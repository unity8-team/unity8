
import os
import subprocess
import time

import dbusmock

from fixtures import Fixture

from unity8.indicators.tests import IndicatorTestCase


class MockUPower(Fixture):

    def setUp(self):

        super().setUp()

        key = 'DBUS_SYSTEM_BUS_ADDRESS'
        if key in os.environ:
            raise OSError('environment variable '+key+' was already set')

        # start a dbusmock system bus and get its address, which looks like
        # "unix:abstract=/tmp/dbus-LQo4Do4ldY,guid=3f7f39089f00884fa96533f354935995"
        dbusmock.DBusTestCase.start_system_bus()
        self.bus_address = os.environ['DBUS_SYSTEM_BUS_ADDRESS'].split(',')[0]

        # start a mock upower service
        self.proxy = dbusmock.DBusTestCase.spawn_server_template(
            'upower',
            {'OnBattery': True, 'HibernateAllowed': False},
            stdout=subprocess.PIPE
        )[1]

    def cleanUp(self):
        self.proxy = None
        self.bus_address = None
        dbusmock.DBusTestCase.tearDownClass()
        super().cleanUp()

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
        return icon_name in widget.icons[0]


class IndicatorPowerTestCase(IndicatorTestCase):

    def setUp(self):
        super().setUp()

        # start a mock UPower service
        self.upower = self.useFixture(MockUPower())

        # restart indicator-power with the mock env variables
        service_test_args = [
            'INDICATOR_POWER_BUS_ADDRESS_UPOWER='+self.upower.bus_address
        ]
        self.start_test_service('indicator-power', *service_test_args)

        # try to get the indicator into the panel
        try:
            self.main_window.wait_select_single(
                objectName='indicator-power-widget'
            )
        except:
            pass

    def test_discharging_battery(self):
        """Test the icon as the battery drains."""

        # tuples of battery states + expected outcomes for those states
        steps = [
            ({'Percentage': 100.0}, {'icon_name': 'battery-100'}),
            ({'Percentage': 95.0}, {'icon_name': 'battery-100'}),
            ({'Percentage': 90.0}, {'icon_name': 'battery-100'}),
            ({'Percentage': 85.0}, {'icon_name': 'battery-080'}),
            ({'Percentage': 80.0}, {'icon_name': 'battery-080'}),
            ({'Percentage': 75.0}, {'icon_name': 'battery-080'}),
            ({'Percentage': 70.0}, {'icon_name': 'battery-080'}),
            ({'Percentage': 65.0}, {'icon_name': 'battery-060'}),
            ({'Percentage': 60.0}, {'icon_name': 'battery-060'}),
            ({'Percentage': 55.0}, {'icon_name': 'battery-060'}),
            ({'Percentage': 50.0}, {'icon_name': 'battery-060'}),
            ({'Percentage': 45.0}, {'icon_name': 'battery-040'}),
            ({'Percentage': 40.0}, {'icon_name': 'battery-040'}),
            ({'Percentage': 35.0}, {'icon_name': 'battery-040'}),
            ({'Percentage': 30.0}, {'icon_name': 'battery-040'}),
            ({'Percentage': 25.0}, {'icon_name': 'battery-020'}),
            ({'Percentage': 20.0}, {'icon_name': 'battery-020'}),
            ({'Percentage': 15.0}, {'icon_name': 'battery-020'}),
            ({'Percentage': 10.0}, {'icon_name': 'battery-020'}),
            ({'Percentage': 5.0}, {'icon_name': 'battery-000'}),
            ({'Percentage': 0.0}, {'icon_name': 'battery-000'})
        ]

        battery_path = self.upower.proxy.AddDischargingBattery(
            'mock_BAT',
            'Mock Battery',
            30.0,
            1200
        )

        indicator = Indicator(self.main_window, 'indicator-power-widget')

        for properties, expected in steps:
            self.upower.proxy.SetDeviceProperties(battery_path, properties)
            # FIXME: sleep() is clumsy..
            time.sleep(1)
            self.assertTrue(indicator.icon_matches(expected['icon_name']))
