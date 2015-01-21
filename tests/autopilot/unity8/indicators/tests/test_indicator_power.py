
import dbus
import os
import subprocess

import dbusmock

from unity8.indicators.tests import IndicatorTestCase


class FakeUPower(object):

    def start(self):
        if 'DBUS_SYSTEM_BUS_ADDRESS' in os.environ:
            raise OSError('environment variable DBUS_SYSTEM_BUS_ADDRESS was already set')

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

    scenarios = [
        ('100.0', {'percentage': 100.0, 'icon_name': 'battery-100'}),
        ('95.0', {'percentage': 95.0, 'icon_name': 'battery-100'}),
        ('90.0', {'percentage': 90.0, 'icon_name': 'battery-100'}),
        ('85.0', {'percentage': 85.0, 'icon_name': 'battery-080'}),
        ('80.0', {'percentage': 80.0, 'icon_name': 'battery-080'}),
        ('75.0', {'percentage': 75.0, 'icon_name': 'battery-080'}),
        ('70.0', {'percentage': 70.0, 'icon_name': 'battery-080'}),
        ('65.0', {'percentage': 65.0, 'icon_name': 'battery-060'}),
        ('60.0', {'percentage': 60.0, 'icon_name': 'battery-060'}),
        ('55.0', {'percentage': 55.0, 'icon_name': 'battery-060'}),
        ('50.0', {'percentage': 50.0, 'icon_name': 'battery-060'}),
        ('45.0', {'percentage': 45.0, 'icon_name': 'battery-040'}),
        ('40.0', {'percentage': 40.0, 'icon_name': 'battery-040'}),
        ('35.0', {'percentage': 35.0, 'icon_name': 'battery-040'}),
        ('30.0', {'percentage': 30.0, 'icon_name': 'battery-040'}),
        ('25.0', {'percentage': 25.0, 'icon_name': 'battery-020'}),
        ('20.0', {'percentage': 20.0, 'icon_name': 'battery-020'}),
        ('15.0', {'percentage': 15.0, 'icon_name': 'battery-020'}),
        ('10.0', {'percentage': 10.0, 'icon_name': 'battery-020'}),
        ('5.0', {'percentage': 5.0, 'icon_name': 'battery-000'}),
        ('0.0', {'percentage': 0.0, 'icon_name': 'battery-000'}),
    ]

    def setUp(self):
        super().setUp()

        # star the mock dbus for upower
        fake_upower_bus = FakeUPower()
        self.fake_upower = fake_upower_bus.start()
        self.addCleanup(fake_upower_bus.stop)
        address = fake_upower_bus.bus_address

        # restart indicator-power with the mock env variables
        self.restart_service(
            'indicator-power',
            ['INDICATOR_POWER_BUS_ADDRESS_UPOWER={}'.format(address)]
        )

        # try to get the indicator into the panel
        try:
            self.main_window.wait_select_single(
                objectName='indicator-power-widget'
            )
        except:
            pass

    def test_discharging_battery(self):
        """Test the icon as the battery drains."""
        battery_path = self.fake_upower.AddDischargingBattery(
            'mock_BAT',
            'Mock Battery',
            30.0,
            1200
        )

        indicator = Indicator(self.main_window, 'indicator-power-widget')
        self.fake_upower.SetDeviceProperties(battery_path, {
            'Percentage': dbus.Double(self.percentage, variant_level=1)
        })
        self.assertTrue(indicator.icon_matches(self.icon_name))
