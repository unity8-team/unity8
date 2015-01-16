
import dbus
import os
import subprocess
import time

import dbusmock

from unity8.indicators.tests import IndicatorTestCase


class FakeUPower(object):

    def start(self):
        # start a dbusmock system bus and get its address, which looks like
        # "unix:abstract=/tmp/dbus-LQo4Do4ldY,guid=3f7f39089f00884fa96533f354935995"
        dbusmock.DBusTestCase.start_system_bus()
        self.bus_address = os.environ['DBUS_SYSTEM_BUS_ADDRESS'].split(',')[0]

        # start a mock upower service
        upower_proxy = dbusmock.DBusTestCase.spawn_server_template(
            'upower',
            {'OnBattery': True, 'HibernateAllowed': False},
            stdout=subprocess.PIPE
        )[1]

        return upower_proxy

    def stop(self):
        dbusmock.DBusTestCase.tearDownClass()
        self.bus_address = None


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
        self.fake_upower_address = fake_upower_bus.bus_address
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
            self.fake_upower_address
        )
        try:
            self.initctl_restart('indicator-power')
            # wait for the indicator to show up
            self.main_window.wait_select_single(
                objectName='indicator-power-widget'
            )
        finally:
            # de-pollute initctl env
            self.initctl_unset_env('INDICATOR_POWER_BUS_ADDRESS_UPOWER')

    def test_discharging_battery(self):
        """Test the icon as the battery drains."""

        battery_path = self.fake_upower.AddDischargingBattery(
            'mock_BAT',
            'Mock Battery',
            30.0,
            1200
        )

        indicator = Indicator(self.main_window, 'indicator-power-widget')

        percentages_and_icon_names = [
            (100.0, 'battery-100'), (95.0, 'battery-100'),
            (90.0, 'battery-100'), (85.0, 'battery-080'),
            (80.0, 'battery-080'), (75.0, 'battery-080'),
            (70.0, 'battery-080'), (65.0, 'battery-060'),
            (60.0, 'battery-060'), (55.0, 'battery-060'),
            (50.0, 'battery-060'), (45.0, 'battery-040'),
            (40.0, 'battery-040'), (35.0, 'battery-040'),
            (30.0, 'battery-040'), (25.0, 'battery-020'),
            (20.0, 'battery-020'), (15.0, 'battery-020'),
            (10.0, 'battery-020'), (5.0, 'battery-000'),
            (0.0, 'battery-000')
        ]

        for percentage, expected_icon_name in percentages_and_icon_names:
            self.fake_upower.SetDeviceProperties(battery_path, {
                'Percentage': dbus.Double(percentage, variant_level=1)
            })
            time.sleep(0.5)  # arbitrary interval for indicator to catch up
            self.assertTrue(indicator.icon_matches(expected_icon_name))
