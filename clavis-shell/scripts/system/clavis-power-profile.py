#!/usr/bin/python3 -I
"""Three CPU power policies for the tested Redmi G firmware/driver combination.

Install a root-owned copy at /usr/local/libexec/clavis-power-profile. Only fixed
`set PROFILE` calls should be allowed via sudo; `status` needs no privileges.
This deliberately does not alter frequency limits, turbo or fan controls.

`set PROFILE --wait=SECONDS` retries while the power daemon or the platform
profile interface is still coming up; the boot default unit uses it.
"""

import fcntl
import json
import os
from pathlib import Path
import subprocess
import sys
import time

SYS = Path('/sys')
POWERPROFILESCTL = '/usr/bin/powerprofilesctl'
PREFERENCES = {
    'power-saver': 'power',
    'balanced': 'balance_power',
    'performance': 'performance',
}

# Failures that clear up once the daemon and firmware driver are ready; only
# these are retried, and only while --wait allows it.
RETRYABLE_ERRORS = (
    'Failed to communicate with power-profiles-daemon',
    'Operation not supported',
)

# power-profiles-daemon applies its own CPU driver asynchronously after the
# platform profile changes, which can land on top of the EPP values written here.
SETTLE_SECONDS = 1.0
SETTLE_ATTEMPTS = 3


def supported():
    expected = {
        'class/dmi/id/product_name': 'Redmi G 2022',
        'class/dmi/id/bios_version': 'RMGAD6T0P1313',
        'class/platform-profile/platform-profile-0/name': 'bitland-mifs-wmi',
    }
    return all((SYS / name).read_text().strip() == value
               for name, value in expected.items())


def policies():
    paths = sorted((SYS / 'devices/system/cpu/cpufreq').glob(
        'policy*/energy_performance_preference'))
    if not paths:
        raise RuntimeError('No CPU energy preference controls are available')
    return paths


def daemon_profile(value=None, wait=0.0):
    args = [POWERPROFILESCTL, 'get'] if value is None else [POWERPROFILESCTL, 'set', value]
    deadline = time.monotonic() + max(0.0, wait)
    while True:
        result = subprocess.run(args, capture_output=True, text=True, timeout=8,
                                env={'PATH': '/usr/bin', 'LC_ALL': 'C'})
        if not result.returncode:
            return result.stdout.strip()
        message = result.stderr.strip() or 'Power profile command failed'
        if (not any(pattern in message for pattern in RETRYABLE_ERRORS)
                or time.monotonic() >= deadline):
            raise RuntimeError(message)
        time.sleep(1.0)


def status(wait=0.0):
    if not supported():
        raise RuntimeError('Unsupported machine, BIOS or platform driver')
    active = daemon_profile(wait=wait)
    # Informational only: this firmware's readback drifts between 'performance'
    # and 'balanced-performance' for the same request, so it cannot decide the
    # active policy. The policy is defined by the daemon profile plus the EPP
    # values this helper writes.
    platform = (SYS / 'firmware/acpi/platform_profile').read_text().strip()
    preferences = sorted({p.read_text().strip() for p in policies()})
    profile = ''
    for candidate, preference in PREFERENCES.items():
        expected_daemon = 'power-saver' if candidate == 'power-saver' else 'performance'
        if active == expected_daemon and preferences == [preference]:
            profile = candidate
            break
    return {'schemaVersion': 1, 'profile': profile,
            'supportedProfiles': list(PREFERENCES), 'daemonProfile': active,
            'platformProfile': platform, 'cpuPreferences': preferences}


def set_profile(profile, wait=0.0):
    if profile not in PREFERENCES:
        raise ValueError('Unknown profile')
    if os.geteuid() != 0:
        raise PermissionError('Setting CPU preferences requires root')
    if not supported():
        raise RuntimeError('Unsupported machine, BIOS or platform driver')
    paths = policies()
    preference = PREFERENCES[profile]
    for p in paths:
        available = p.with_name('energy_performance_available_preferences').read_text().split()
        if preference not in available:
            raise RuntimeError(f'{p.parent.name} does not support {preference}')
    previous_daemon = daemon_profile(wait=wait)
    previous_preferences = {p: p.read_text().strip() for p in paths}
    try:
        # On this firmware, requesting balanced reads back platform performance.
        daemon_profile('power-saver' if profile == 'power-saver' else 'balanced',
                       wait=wait)
        # Only a real daemon profile change makes the daemon re-apply its own
        # CPU driver, so only then is a settle delay needed.
        expected_daemon = 'power-saver' if profile == 'power-saver' else 'performance'
        if previous_daemon != expected_daemon:
            time.sleep(SETTLE_SECONDS)
        for attempt in range(SETTLE_ATTEMPTS):
            for p in paths:
                p.write_text(preference + '\n')
            result = status(wait=wait)
            if result['profile'] == profile:
                return result
            if attempt + 1 < SETTLE_ATTEMPTS:
                time.sleep(SETTLE_SECONDS)
        raise RuntimeError('Requested policy did not match the actual CPU state')
    except Exception as error:
        rollback_errors = []
        try:
            daemon_profile('power-saver' if previous_daemon == 'power-saver' else 'balanced')
        except Exception as rollback_error:
            rollback_errors.append(str(rollback_error))
        for p, value in previous_preferences.items():
            try:
                p.write_text(value + '\n')
            except Exception as rollback_error:
                rollback_errors.append(str(rollback_error))
        if rollback_errors:
            raise RuntimeError(f'{error}; rollback failed: {rollback_errors}') from error
        raise


def wait_argument(args):
    if not args:
        return 0.0
    if len(args) > 1 or not args[0].startswith('--wait='):
        raise ValueError('Usage: clavis-power-profile status | set PROFILE [--wait=SECONDS]')
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
    if len(args) >= 2 and args[0] == 'set' and args[1] in PREFERENCES:
        wait = wait_argument(args[2:])
        # Serialize boot defaults and interactive changes. Never use a caller path.
        try:
            with open('/run/clavis-power-profile.lock', 'a', encoding='utf-8') as lock:
                fcntl.flock(lock, fcntl.LOCK_EX)
                return set_profile(args[1], wait)
        except OSError as error:
            raise RuntimeError(f'Unable to lock or apply CPU power policy: {error}') from error
    raise ValueError('Usage: clavis-power-profile status | set PROFILE [--wait=SECONDS]')


if __name__ == '__main__':
    try:
        print(json.dumps(main(sys.argv[1:])))
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
