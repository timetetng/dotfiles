#!/usr/bin/python3 -I
"""Clavis power policy adapter for the tested Redmi G firmware/driver pair.

Install a root-owned copy at /usr/local/libexec/clavis-power-profile. Only fixed
`set PROFILE` / `gpu LEVEL` calls are allowlisted via sudo; `status` needs no
privileges.

All CPU/ACPI/GPU writes live in the `powermode` helper installed next to this
file (clavis-powermode), so the bar, the boot default unit and the terminal share
one implementation. This wrapper only validates arguments, gates on the known
firmware combination and translates powermode's JSON into the shell's schema.

`set` deliberately does not roll back on failure: powermode already writes only
to a verified end state, and the shell exposes「重新应用」for a daemon/CPU
mismatch.
"""

import fcntl
import json
import os
from pathlib import Path
import subprocess
import sys
import time

SYS = Path('/sys')
POWERMODE = Path('/usr/local/libexec/clavis-powermode')
POWERPROFILESCTL = '/usr/bin/powerprofilesctl'
PROFILES = ('power-saver', 'balanced', 'performance')
GPU_LEVELS = ('0', '1', '2', '3')
ENV = {'PATH': '/usr/local/bin:/usr/bin', 'LC_ALL': 'C'}
COMMAND_TIMEOUT = 30
RETRY_SECONDS = 1.0
LOCK_PATH = '/run/clavis-power-profile.lock'


def supported():
    expected = {
        'class/dmi/id/product_name': 'Redmi G 2022',
        'class/dmi/id/bios_version': 'RMGAD6T0P1313',
        'class/platform-profile/platform-profile-0/name': 'bitland-mifs-wmi',
    }
    try:
        return all((SYS / name).read_text().strip() == value
                   for name, value in expected.items())
    except OSError:
        return False


def run(command, timeout=COMMAND_TIMEOUT):
    result = subprocess.run([str(part) for part in command], capture_output=True,
                            text=True, timeout=timeout, env=ENV)
    if result.returncode:
        message = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(message or f'{Path(str(command[0])).name} failed')
    return result.stdout.strip()


def daemon_ready(wait=0.0):
    """The daemon applies its own CPU driver asynchronously; wait for it at boot."""
    deadline = time.monotonic() + max(0.0, wait)
    while True:
        result = subprocess.run([POWERPROFILESCTL, 'get'], capture_output=True,
                                text=True, timeout=8, env=ENV)
        if not result.returncode:
            return
        if time.monotonic() >= deadline:
            raise RuntimeError(result.stderr.strip() or 'Power daemon did not become ready')
        time.sleep(RETRY_SECONDS)


def status():
    if not supported():
        raise RuntimeError('Unsupported machine, BIOS or platform driver')
    try:
        result = json.loads(run([POWERMODE, 'status', '--json'], timeout=15))
    except json.JSONDecodeError as error:
        raise RuntimeError(f'powermode returned invalid JSON: {error}') from None
    if result.get('schemaVersion') != 1:
        raise RuntimeError('powermode returned an unsupported schema version')
    if not isinstance(result.get('supportedProfiles'), list) \
            or not all(profile in result['supportedProfiles'] for profile in PROFILES):
        raise RuntimeError('powermode did not report the three CPU profiles')
    profile = result.get('profile') if result.get('profile') in PROFILES else ''
    levels = result.get('gpuLevelNames')
    if not isinstance(levels, list) or len(levels) != len(GPU_LEVELS):
        raise RuntimeError('powermode did not report the four GPU levels')
    return {
        'schemaVersion': 1,
        'profile': profile,
        'supportedProfiles': list(PROFILES),
        'daemonProfile': str(result.get('daemonProfile', '')),
        'platformProfile': str(result.get('platformProfile', '')),
        'cpuPreferences': [str(value) for value in result.get('cpuPreferences', [])],
        'gpuLevel': int(result.get('gpuLevel', 0)),
        'gpuLevelName': str(result.get('gpuLevelName', '')),
        'gpuLevelNames': [str(name) for name in levels],
        'gpuLock': str(result.get('gpuLock', '')),
        'igpuCap': int(result.get('igpuCap', 0)),
    }


def require_root_and_hardware():
    if os.geteuid() != 0:
        raise PermissionError('Changing power policy requires root')
    if not supported():
        raise RuntimeError('Unsupported machine, BIOS or platform driver')


def locked(action, wait=0.0):
    """Serialize boot defaults and interactive changes; never use a caller path."""
    try:
        with open(LOCK_PATH, 'a', encoding='utf-8') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            daemon_ready(wait)
            action()
    except OSError as error:
        raise RuntimeError(f'Unable to lock or apply power policy: {error}') from error


def set_profile(profile, wait=0.0):
    if profile not in PROFILES:
        raise ValueError('Unknown profile')
    require_root_and_hardware()
    locked(lambda: run([POWERMODE, profile]), wait)
    return status()


def set_gpu(level):
    if level not in GPU_LEVELS:
        raise ValueError('Unknown GPU level')
    require_root_and_hardware()
    locked(lambda: run([POWERMODE, 'gpu', level]))
    return status()


def wait_argument(args):
    if not args:
        return 0.0
    if len(args) > 1 or not args[0].startswith('--wait='):
        raise ValueError('Usage: clavis-power-profile status | set PROFILE [--wait=SECONDS] | gpu LEVEL')
    try:
        wait = float(args[0][len('--wait='):])
    except ValueError:
        raise ValueError('Invalid wait duration') from None
    if not 0 <= wait <= 300:
        raise ValueError('Invalid wait duration')
    return wait


def main(args):
    if args == ['status']:
        return status()
    if len(args) >= 2 and args[0] == 'set':
        return set_profile(args[1], wait_argument(args[2:]))
    if len(args) == 2 and args[0] == 'gpu':
        return set_gpu(args[1])
    raise ValueError('Usage: clavis-power-profile status | set PROFILE [--wait=SECONDS] | gpu LEVEL')


if __name__ == '__main__':
    try:
        print(json.dumps(main(sys.argv[1:])))
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
