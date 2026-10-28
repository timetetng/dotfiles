"""Policy/readback and rollback tests using fake sysfs; never changes the host."""

import importlib.util
from pathlib import Path
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

    def daemon_profile(self, value=None):
        if value is not None:
            if value not in ('balanced', 'power-saver'):
                raise RuntimeError('Firmware rejects direct performance requests')
            self.daemon = 'performance' if value == 'balanced' else value
            self.put('firmware/acpi/platform_profile',
                     'performance' if value == 'balanced' else 'low-power')
        return self.daemon

    def test_three_policies_round_trip(self):
        with patch.object(power, 'daemon_profile', self.daemon_profile), \
                patch.object(power.os, 'geteuid', return_value=0):
            for profile in ('balanced', 'power-saver', 'performance', 'balanced'):
                result = power.set_profile(profile)
                self.assertEqual(result['profile'], profile)
                self.assertEqual(result['cpuPreferences'], [power.PREFERENCES[profile]])
                self.assertEqual(power.status()['profile'], profile)

    def test_mixed_cpu_preferences_are_not_misreported(self):
        power.policies()[0].write_text('balance_power\n')
        with patch.object(power, 'daemon_profile', self.daemon_profile):
            self.assertEqual(power.status()['profile'], '')

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

    def test_set_requires_root(self):
        with patch.object(power.os, 'geteuid', return_value=1000):
            with self.assertRaises(PermissionError):
                power.set_profile('balanced')


if __name__ == '__main__':
    unittest.main()
