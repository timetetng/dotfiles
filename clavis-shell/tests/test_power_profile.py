"""Contract tests for the Clavis power adapter; uses a fake powermode, never the host."""

import importlib.util
import json
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


class PowerAdapterTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.sys = Path(self.directory.name)
        self.lock = self.sys / 'lock'
        self.calls = []
        self.payload = {
            'schemaVersion': 1,
            'profile': 'balanced',
            'supportedProfiles': ['power-saver', 'balanced', 'performance'],
            'daemonProfile': 'performance',
            'platformProfile': 'performance',
            'cpuPreferences': ['balance_power'],
            'gpuLevel': 2,
            'gpuLevelName': '中',
            'gpuLock': '405,1800',
            'igpuCap': 900,
            'gpuLevelNames': ['省电', '低', '中', '不限'],
        }
        for name, value in {
            'class/dmi/id/product_name': 'Redmi G 2022',
            'class/dmi/id/bios_version': 'RMGAD6T0P1313',
            'class/platform-profile/platform-profile-0/name': 'bitland-mifs-wmi',
        }.items():
            path = self.sys / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(value + '\n')
        for attribute, value in (('SYS', self.sys), ('LOCK_PATH', str(self.lock))):
            patcher = patch.object(power, attribute, value)
            patcher.start()
            self.addCleanup(patcher.stop)
        patcher = patch.object(power, 'run', side_effect=self.fake_run)
        patcher.start()
        self.addCleanup(patcher.stop)
        patcher = patch.object(power.os, 'geteuid', return_value=0)
        patcher.start()
        self.addCleanup(patcher.stop)

    def fake_run(self, command, timeout=None):
        self.calls.append([str(part) for part in command])
        if [str(part) for part in command][1:] == ['status', '--json']:
            return json.dumps(self.payload)
        return ''

    def test_status_reports_three_profiles_and_four_gpu_levels(self):
        result = power.status()
        self.assertEqual(result['schemaVersion'], 1)
        self.assertEqual(result['profile'], 'balanced')
        self.assertEqual(result['gpuLevel'], 2)
        self.assertEqual(result['gpuLevelNames'], ['省电', '低', '中', '不限'])
        self.assertEqual(self.calls[-1][1:], ['status', '--json'])

    def test_unclassified_epp_reports_empty_profile(self):
        self.payload['profile'] = ''
        self.assertEqual(power.status()['profile'], '')

    def test_missing_gpu_levels_are_rejected(self):
        self.payload['gpuLevelNames'] = ['省电']
        with self.assertRaisesRegex(RuntimeError, 'four GPU levels'):
            power.status()

    def test_set_runs_the_matching_powermode_profile(self):
        self.assertEqual(power.set_profile('power-saver')['profile'], 'balanced')
        self.assertIn(['/usr/local/libexec/clavis-powermode', 'power-saver'], self.calls)

    def test_gpu_level_is_validated_before_running_anything(self):
        power.set_gpu('1')
        self.assertIn(['/usr/local/libexec/clavis-powermode', 'gpu', '1'], self.calls)
        for value in ('4', '-1', '../etc/shadow', 'low'):
            with self.assertRaises(ValueError):
                power.set_gpu(value)

    def test_unknown_profile_and_extra_arguments_are_rejected(self):
        with self.assertRaises(ValueError):
            power.set_profile('../../etc/shadow')
        with self.assertRaises(ValueError):
            power.main(['set', 'balanced', 'extra-argument'])
        with self.assertRaises(ValueError):
            power.main(['gpu'])

    def test_root_is_required_for_changes(self):
        with patch.object(power.os, 'geteuid', return_value=1000):
            with self.assertRaises(PermissionError):
                power.set_profile('balanced')
            with self.assertRaises(PermissionError):
                power.set_gpu('3')
        self.assertEqual(self.calls, [])

    def test_unsupported_hardware_is_not_written(self):
        (self.sys / 'class/dmi/id/product_name').write_text('Different model\n')
        with self.assertRaisesRegex(RuntimeError, 'Unsupported'):
            power.set_profile('balanced')
        with self.assertRaisesRegex(RuntimeError, 'Unsupported'):
            power.status()
        self.assertEqual(self.calls, [])

    def test_daemon_not_ready_is_retried_while_waiting(self):
        attempts = []

        def get(_command, **kwargs):
            attempts.append(_command)
            ready = len(attempts) >= 3
            return subprocess.CompletedProcess(
                _command, 0 if ready else 1, 'performance\n' if ready else '',
                '' if ready else 'Failed to communicate with power-profiles-daemon')

        with patch.object(power.subprocess, 'run', side_effect=get), \
                patch.object(power.time, 'sleep'):
            power.set_profile('balanced', wait=5)
        self.assertEqual(len(attempts), 3)

    def test_daemon_failure_without_wait_is_not_retried(self):
        failure = subprocess.CompletedProcess(
            [], 1, '', 'Failed to communicate with power-profiles-daemon')
        with patch.object(power.subprocess, 'run', return_value=failure), \
                self.assertRaisesRegex(RuntimeError, 'Failed to communicate'):
            power.set_profile('balanced')
        self.assertEqual(self.calls, [])

    def test_wait_argument_is_validated(self):
        for argument in ('--wait=abc', '--wait=-1', '--wait=301', '--wait=5s', 'extra'):
            with self.assertRaises(ValueError):
                power.wait_argument([argument])
        self.assertEqual(power.wait_argument([]), 0.0)
        self.assertEqual(power.wait_argument(['--wait=45']), 45.0)


if __name__ == '__main__':
    unittest.main()
