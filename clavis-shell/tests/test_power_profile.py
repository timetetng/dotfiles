"""Policy/readback and rollback tests using fake sysfs; never changes the host."""

import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    'power_profile', Path(__file__).resolve().parents[1] / 'scripts/system/clavis-power-profile.py')
assert SPEC is not None and SPEC.loader is not None
power = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(power)


class PowerProfileTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.sys = Path(self.directory.name)
        self.patch = patch.object(power, 'SYS', self.sys)
        self.patch.start()
        self.addCleanup(self.patch.stop)
        for name, value in {
            'class/dmi/id/product_name': 'Redmi G 2022',
            'class/dmi/id/bios_version': 'RMGAD6T0P1313',
            'class/platform-profile/platform-profile-0/name': 'bitland-mifs-wmi',
            'firmware/acpi/platform_profile': 'performance',
        }.items():
            self.put(name, value)
        for cpu in range(2):
            base = f'devices/system/cpu/cpufreq/policy{cpu}/'
            self.put(base + 'energy_performance_preference', 'performance')
            self.put(base + 'energy_performance_available_preferences',
                     'default performance balance_performance balance_power power')
        self.daemon = 'performance'

    def put(self, name, value):
        path = self.sys / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(value + '\n')

    def daemon_profile(self, value=None, wait=0.0):
        if value is not None:
            if value not in ('balanced', 'power-saver'):
                raise RuntimeError('Firmware rejects direct performance requests')
            self.daemon = 'performance' if value == 'balanced' else value
            self.put('firmware/acpi/platform_profile',
                     'performance' if value == 'balanced' else 'low-power')
        return self.daemon

    def test_three_policies_round_trip(self):
        with patch.object(power, 'daemon_profile', self.daemon_profile), \
                patch.object(power.os, 'geteuid', return_value=0), \
                patch.object(power.time, 'sleep'):
            for profile in ('balanced', 'power-saver', 'performance', 'balanced'):
                result = power.set_profile(profile)
                self.assertEqual(result['profile'], profile)
                self.assertEqual(result['cpuPreferences'], [power.PREFERENCES[profile]])
                self.assertEqual(power.status()['profile'], profile)

    def test_mixed_cpu_preferences_are_not_misreported(self):
        power.policies()[0].write_text('balance_power\n')
        with patch.object(power, 'daemon_profile', self.daemon_profile):
            self.assertEqual(power.status()['profile'], '')

    def test_platform_profile_drift_is_not_an_error(self):
        # Firmware readback drifts between the two values for identical requests;
        # only the daemon profile and EPP decide which policy is active.
        for profile, platform in (('balanced', 'balanced-performance'),
                                  ('performance', 'balanced-performance'),
                                  ('performance', 'performance')):
            self.put('firmware/acpi/platform_profile', platform)
            for cpu in range(2):
                self.put(f'devices/system/cpu/cpufreq/policy{cpu}/energy_performance_preference',
                         power.PREFERENCES[profile])
            with patch.object(power, 'daemon_profile', return_value='performance'):
                result = power.status()
            self.assertEqual(result['profile'], profile)
            self.assertEqual(result['platformProfile'], platform)

    def test_readback_failure_restores_previous_policy(self):
        before = {p: p.read_text() for p in power.policies()}
        with patch.object(power, 'daemon_profile', self.daemon_profile), \
                patch.object(power.os, 'geteuid', return_value=0), \
                patch.object(power, 'status', side_effect=RuntimeError('readback failed')):
            with self.assertRaisesRegex(RuntimeError, 'readback failed'):
                power.set_profile('power-saver')
        self.assertEqual(self.daemon, 'performance')
        self.assertEqual({p: p.read_text() for p in power.policies()}, before)

    def test_unsupported_hardware_is_not_written(self):
        self.put('class/dmi/id/product_name', 'Different model')
        with patch.object(power.os, 'geteuid', return_value=0), \
                patch.object(power, 'daemon_profile') as daemon:
            with self.assertRaisesRegex(RuntimeError, 'Unsupported'):
                power.set_profile('balanced')
            daemon.assert_not_called()

    def test_unknown_policy_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'Unknown profile'):
            power.set_profile('../../etc/shadow')
        with self.assertRaises(ValueError):
            power.main(['set', 'balanced', 'extra-argument'])

    def test_daemon_not_ready_is_retried(self):
        calls = []

        def run(args, **kwargs):
            calls.append(args)
            if len(calls) < 3:
                return subprocess.CompletedProcess(
                    args, 1, '',
                    'Failed to communicate with power-profiles-daemon: no name owner')
            return subprocess.CompletedProcess(args, 0, 'performance\n', '')

        with patch.object(power.subprocess, 'run', side_effect=run), \
                patch.object(power.time, 'sleep'):
            self.assertEqual(power.daemon_profile(wait=5), 'performance')
        self.assertEqual(len(calls), 3)

    def test_transient_failure_without_wait_is_not_retried(self):
        with patch.object(power.subprocess, 'run',
                          return_value=subprocess.CompletedProcess(
                              [], 1, '', 'Power profile command failed')) as run:
            with self.assertRaisesRegex(RuntimeError, 'Power profile command failed'):
                power.daemon_profile()
            self.assertEqual(run.call_count, 1)

    def test_wait_argument_is_validated(self):
        for argument in ('--wait=abc', '--wait=-1', '--wait=301', '--wait=5s', 'extra'):
            with self.assertRaises(ValueError):
                power.main(['set', 'balanced', argument])

    def test_daemon_reapply_after_write_is_corrected(self):
        real_status = power.status
        calls = []

        def status_with_one_reapply(wait=0.0):
            calls.append(wait)
            if len(calls) == 1:
                # ppd's own CPU driver lands after ours and resets EPP.
                for p in power.policies():
                    p.write_text('performance\n')
            return real_status(wait=wait)

        with patch.object(power, 'daemon_profile', self.daemon_profile), \
                patch.object(power.os, 'geteuid', return_value=0), \
                patch.object(power.time, 'sleep'), \
                patch.object(power, 'status', status_with_one_reapply):
            result = power.set_profile('balanced')
        self.assertEqual(result['profile'], 'balanced')
        self.assertEqual(len(calls), 2)
        self.assertEqual({p.read_text() for p in power.policies()}, {'balance_power\n'})

    def test_no_settle_delay_when_daemon_already_matches(self):
        with patch.object(power, 'daemon_profile', self.daemon_profile), \
                patch.object(power.os, 'geteuid', return_value=0), \
                patch.object(power.time, 'sleep') as sleep:
            power.set_profile('balanced')
            sleep.assert_not_called()
            power.set_profile('performance')
            sleep.assert_not_called()

    def test_set_requires_root(self):
        with patch.object(power.os, 'geteuid', return_value=1000):
            with self.assertRaises(PermissionError):
                power.set_profile('balanced')


if __name__ == '__main__':
    unittest.main()
