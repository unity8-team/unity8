
import dbus
import fcntl
import os
import subprocess
import time
import unittest

import dbusmock
from autopilot.matchers import Eventually
from autopilot import platform

from unity8.process_helpers import unlock_unity
from unity8.shell.tests import UnityTestCase, _get_device_emulation_scenarios


# PLEASE IGNORE THIS BIT FOR NOW
# class FakeUPowerException(Exception):
#     pass
# 
# 
# class FakeUPowerService:
# 
#     """Fake upower service using a dbusmock interface."""
# 
#     def __init__(self):
#         super(FakeUPowerService, self).__init__()
#         self.dbus_connection = dbusmock.DBusTestCase.get_dbus(system_bus=False)
# 
#     def start(self):
#         """Start the fake URL Dispatcher service."""
#         # Stop the real url-dispatcher.
#         subprocess.call(['initctl', 'stop', 'url-dispatcher'])
#         self.dbus_mock_server = dbusmock.DBusTestCase.spawn_server(
#             'com.canonical.UPower',
#             '/com/canonical/UPower',
#             'com.canonical.UPower',
#             system_bus=False,
#             stdout=subprocess.PIPE)
#         self.mock = self._get_mock_interface()
#         self.mock.AddMethod(
#             'com.canonical.UPower', 'DispatchURL', 'ss', '', '')
# 
#     def _get_mock_interface(self):
#         return dbus.Interface(
#             self.dbus_connection.get_object(
#                 'com.canonical.UPower',
#                 '/com/canonical/UPower'),
#             dbusmock.MOCK_IFACE)
# 
#     def stop(self):
#         """Stop the fake URL Dispatcher service."""
#         self.dbus_mock_server.terminate()
#         self.dbus_mock_server.wait()
# 
#     def get_last_dispatch_url_call_parameter(self):
#         """Return the parameter used in the last call to dispatch URL."""
#         calls = self.mock.GetCalls()
#         if len(calls) == 0:
#             raise FakeDispatcherException(
#                 'URL dispatcher has not been called.')
#         last_call = self.mock.GetCalls()[-1]
#         return last_call[2][0]


def initctl_set_env(variable, value):
    """initctl set-env to set the environmnent variable to given value."""
    subprocess.call(['initctl', 'set-env', '-g', '{}={}'.format(variable, value)])

def initctl_unset_env(variable):
    """initctl unset-env to unset the environmnent variable."""
    subprocess.call(['initctl', 'unset-env', '-g', '{}'.format(variable)])

def initctl_restart(service_name):
    """initctl restart service of given name."""
    subprocess.call(['initctl', 'restart', service_name])


class IndicatorPowerTestCase(UnityTestCase):

    device_emulation_scenarios = _get_device_emulation_scenarios()

    def setUp(self):
        if platform.model() == 'Desktop' and 'GRID_UNIT_PX' not in os.environ:
            os.environ['GRID_UNIT_PX'] = '13'
        super(IndicatorPowerTestCase, self).setUp()
        self.unity_proxy = self.launch_unity()
        unlock_unity(self.unity_proxy)

        dbusmock.DBusTestCase.start_system_bus()
        (self.p_mock, self.obj_upower) = dbusmock.DBusTestCase.spawn_server_template(
            'upower', {'OnBattery': True, 'HibernateAllowed': False}, stdout=subprocess.PIPE)
        # set log to nonblocking
        flags = fcntl.fcntl(self.p_mock.stdout, fcntl.F_GETFL)
        fcntl.fcntl(self.p_mock.stdout, fcntl.F_SETFL, flags | os.O_NONBLOCK)
        self.dbusmock = dbus.Interface(self.obj_upower, dbusmock.MOCK_IFACE)
        self.restart_indicator_power_listening_to_fake_bus()
        initctl_set_env('G_MESSAGES_DEBUG', 'all')

    def tearDown(self):
        # This feels icky but no public accessors are available.
        if dbusmock.DBusTestCase.system_bus_pid is not None:
            dbusmock.DBusTestCase.stop_dbus(dbusmock.DBusTestCase.system_bus_pid)
            del os.environ['DBUS_SYSTEM_BUS_ADDRESS']
            dbusmock.DBusTestCase.system_bus_pid = None
        super(IndicatorPowerTestCase, self).tearDown()

    def restart_indicator_power_listening_to_fake_bus(self):
        """Restart indicator-power listening to fake bus.

        Set the upstart initctl environment and initctl restart
        indicator-power, unsetting the env.

        """
        bus_address_string = os.environ['DBUS_SYSTEM_BUS_ADDRESS']
        # looks like:
        # unix:abstract=/tmp/dbus-LQo4Do4ldY,guid=3f7f39089f00884fa96533f354935995  # NOQA
        self.bus_address = bus_address_string.split(',')[0]
        initctl_set_env(
            'INDICATOR_POWER_BUS_ADDRESS_UPOWER',
            self.bus_address
        )
        initctl_restart('indicator-power')
        
        # FIXME: wait for the bus to spin up
        # self.assertThat(
        #     bus.get_object(
        #         'org.freedesktop.UPower',
        #         '/org/freedesktop/UPower'),
        #     Eventually(NotEquals(None))
        # )

        # initctl_unset_env('INDICATOR_POWER_BUS_ADDRESS_UPOWER')


    def test_discharging_battery(self):
        path = self.dbusmock.AddDischargingBattery('mock_BAT', 'Mock Battery', 30.0, 1200)
        self.assertEqual(path, '/org/freedesktop/UPower/devices/mock_BAT')
        bus = dbus.bus.BusConnection(self.bus_address)
        
        self.assertRegex(self.p_mock.stdout.read(),
                         b'emit org.freedesktop.UPower.DeviceAdded '
                         b'"/org/freedesktop/UPower/devices/mock_BAT"\n')

        out = subprocess.check_output(['upower', '--dump'],
                                      universal_newlines=True)
        self.assertRegex(out, 'Device: ' + path)
        # note, Add* is not magic: this just adds an object, not change
        # properties
        self.assertRegex(out, 'on-battery:\s+yes')
        self.assertRegex(out, 'lid-is-present:\s+yes')
        self.assertRegex(out, ' present:\s+yes')
        self.assertRegex(out, ' percentage:\s+30%')
        self.assertRegex(out, ' time to empty:\s+20.0 min')
        self.assertRegex(out, ' state:\s+discharging')

        correct_icon_name = 'battery-040'

        # widget = self.main_window.wait_select_single(
        #     objectName='indicator-power-widget'
        # )
        # # looks like [dbus.String('image://theme/battery-040,gpm-battery-040,battery-good-symbolic,battery-good')]  # NOQA
        # observed_icon_string = widget.icons[0]
        # self.assertIn(correct_icon_name, observed_icon_string)

        indicator = Indicator(self.main_window, 'indicator-power-widget')
        self.assertTrue(indicator.icon_matches(correct_icon_name))



class Indicator(object):

    def __init__(self, main_window, name):
        self.name = name
        widget = main_window.wait_select_single(
            objectName=name
        )
        # looks like [dbus.String('image://theme/battery-040,gpm-battery-040,battery-good-symbolic,battery-good')]  # NOQA
        self.observed_icon_string = widget.icons[0]
        
    def icon_matches(self, icon_name):
        return icon_name in self.observed_icon_string
