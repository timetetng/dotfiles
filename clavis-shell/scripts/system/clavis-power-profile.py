#!/usr/bin/python3 -I
"""Three CPU power policies for the tested Redmi G firmware/driver combination.

Install a root-owned copy at /usr/local/libexec/clavis-power-profile. Only fixed
`set PROFILE` calls should be allowed via sudo; `status` needs no privileges.
This deliberately does not alter frequency limits, turbo or fan controls.
"""

import fcntl
import json
import os
from pathlib import Path
import subprocess
import sys

SYS = Path('/sys')
POWERPROFILESCTL = '/usr/bin/powerprofilesctl'
PREFERENCES = {
    'power-saver': 'power',
    'balanced': 'balance_power',
    'performance': 'performance',
}


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


def daemon_profile(value=None):
    args = [POWERPROFILESCTL, 'get'] if value is None else [POWERPROFILESCTL, 'set', value]
    result = subprocess.run(args, capture_output=True, text=True, timeout=8,
                            env={'PATH': '/usr/bin', 'LC_ALL': 'C'})
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or 'Power profile command failed')
    return result.stdout.strip()


def status():
    if not supported():
        raise RuntimeError('Unsupported machine, BIOS or platform driver')
    active = daemon_profile()
    platform = (SYS / 'firmware/acpi/platform_profile').read_text().strip()
    preferences = sorted({p.read_text().strip() for p in policies()})
    profile = ''
    for candidate, preference in PREFERENCES.items():
        expected_daemon = 'power-saver' if candidate == 'power-saver' else 'performance'
        expected_platform = 'low-power' if candidate == 'power-saver' else 'performance'
        if (active == expected_daemon and platform == expected_platform
                and preferences == [preference]):
            profile = candidate
            break
    return {'schemaVersion': 1, 'profile': profile,
            'supportedProfiles': list(PREFERENCES), 'daemonProfile': active,
            'platformProfile': platform, 'cpuPreferences': preferences}


def set_profile(profile):
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
    previous_daemon = daemon_profile()
    previous_preferences = {p: p.read_text().strip() for p in paths}
    try:
        # On this firmware, requesting balanced reads back platform performance.
        daemon_profile('power-saver' if profile == 'power-saver' else 'balanced')
        for p in paths:
            p.write_text(preference + '\n')
        result = status()
        if result['profile'] != profile:
            raise RuntimeError('Requested policy did not match the actual CPU/platform state')
        return result
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


def main(args):
    if args == ['status']:
        return status()
    if len(args) == 2 and args[0] == 'set' and args[1] in PREFERENCES:
        # Serialize boot defaults and interactive changes. Never use a caller path.
        try:
            with open('/run/clavis-power-profile.lock', 'a', encoding='utf-8') as lock:
                fcntl.flock(lock, fcntl.LOCK_EX)
                return set_profile(args[1])
        except OSError as error:
            raise RuntimeError(f'Unable to lock or apply CPU power policy: {error}') from error
    raise ValueError('Usage: clavis-power-profile status | set {power-saver,balanced,performance}')


if __name__ == '__main__':
    try:
        print(json.dumps(main(sys.argv[1:])))
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
