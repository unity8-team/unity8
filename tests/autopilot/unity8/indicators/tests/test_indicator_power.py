
import os
import subprocess
import time

import dbusmock

from fixtures import Fixture

from unity8.indicators.tests import IndicatorTestCase
from unity8.indicators.helpers.indicator import Indicator


class MockBattery(object):

    def __init__(self, proxy, object_path):
        self.proxy = proxy
        self.object_path = object_path

    def set_properties(self, properties):
        self.proxy.SetDeviceProperties(self.object_path, properties)


class MockUPower(Fixture):

    def setUp(self):

        super().setUp()

        self._battery_count = 0

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

        self.addCleanup(self._cleanUp)

    def _cleanUp(self):
        self.proxy = None
        self.bus_address = None
        dbusmock.DBusTestCase.tearDownClass()

    def add_discharging_battery(
            self,
            model_name='Mock Battery',
            percentage=30.0,
            seconds_until_empty=1200):

        # uniqueness required; this becomes part of the device's object_path
        device_name = 'mock_BAT{}'.format(self._battery_count)
        self._battery_count += 1

        object_path = self.proxy.AddDischargingBattery(
            device_name,
            model_name,
            percentage,
            seconds_until_empty
        )

        return MockBattery(self.proxy, object_path)


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

        battery = self.upower.add_discharging_battery()

        indicator = Indicator(self.main_window, 'indicator-power-widget')

        for properties, expected in steps:
            battery.set_properties(properties)
            # FIXME: sleep() is clumsy..
            time.sleep(1)
            self.assertTrue(indicator.icon_matches(expected['icon_name']))
