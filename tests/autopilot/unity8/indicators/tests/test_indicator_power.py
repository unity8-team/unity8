
import dbus
import os
import subprocess

import dbusmock

from unity8.indicators.tests import IndicatorTestCase


def get_fake_system_bus_address():
    """Return dbusmock's fake system bus address."""
    bus_address_string = os.environ['DBUS_SYSTEM_BUS_ADDRESS']
    # looks like:
    # unix:abstract=/tmp/dbus-LQo4Do4ldY,guid=3f7f39089f00884fa96533f354935995  # NOQA
    return bus_address_string.split(',')[0]


class FakeUPower(object):

    def start(self):
        dbusmock.DBusTestCase.start_system_bus()
        p_mock, obj_upower = dbusmock.DBusTestCase.spawn_server_template(
            'upower',
            {'OnBattery': True, 'HibernateAllowed': False},
            stdout=subprocess.PIPE
        )
        mock_interface = dbus.Interface(obj_upower, dbusmock.MOCK_IFACE)
        bus = dbus.bus.BusConnection(get_fake_system_bus_address())
        bus.get_object('org.freedesktop.UPower', '/org/freedesktop/UPower')
        return mock_interface

    def stop(self):
        # This feels icky but no public accessors are available.
        if dbusmock.DBusTestCase.system_bus_pid is not None:
            dbusmock.DBusTestCase.stop_dbus(
                dbusmock.DBusTestCase.system_bus_pid
            )
            del os.environ['DBUS_SYSTEM_BUS_ADDRESS']
            dbusmock.DBusTestCase.system_bus_pid = None


class Indicator(object):

    def __init__(self, main_window, name):
        self.main_window = main_window
        self.name = name

    def icon_matches(self, icon_name):
        """Does the icon match the given well-known icon name?"""
        widget = self.main_window.wait_select_single(
            objectName=self.name
        )
        # looks like [dbus.String('image://theme/battery-040,gpm-battery-040,battery-good-symbolic,battery-good')]  # NOQA
        self.observed_icon_string = widget.icons[0]
        return icon_name in self.observed_icon_string


class IndicatorPowerTestCase(IndicatorTestCase):

    def setUp(self):
        super(IndicatorPowerTestCase, self).setUp()
        fake_upower_bus = FakeUPower()
        self.fake_upower = fake_upower_bus.start()
        self.addCleanup(fake_upower_bus.stop)
        self.restart_indicator_power_listening_to_fake_bus()
        # restart the indicator listening to the authentic UPower bus
        self.addCleanup(self.initctl_restart, 'indicator-power')

    def restart_indicator_power_listening_to_fake_bus(self):
        """Restart indicator-power listening to fake bus.

        Set the upstart initctl environment and initctl restart
        indicator-power, unsetting the env.

        """
        self.initctl_set_env(
            'INDICATOR_POWER_BUS_ADDRESS_UPOWER',
            get_fake_system_bus_address()
        )
        self.initctl_restart('indicator-power')
        # wait for the indicator to show up
        self.main_window.wait_select_single(
            objectName='indicator-power-widget'
        )
        # de-pollute initctl env
        self.initctl_unset_env('INDICATOR_POWER_BUS_ADDRESS_UPOWER')

    def test_discharging_battery(self):
        """Battery icon must match UPower-reported level."""
        self.fake_upower.AddDischargingBattery(
            'mock_BAT',
            'Mock Battery',
            30.0,
            1200
        )
        correct_icon_name = 'battery-040'
        indicator = Indicator(self.main_window, 'indicator-power-widget')
        self.assertTrue(indicator.icon_matches(correct_icon_name))
