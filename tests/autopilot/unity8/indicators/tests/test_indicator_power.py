# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Unity - Indicators Autopilot Test Suite
# Copyright (C) 2015 Canonical
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import os
import subprocess

from autopilot.matchers import Eventually
import dbusmock
from fixtures import Fixture
from testtools.matchers import Contains

from unity8.indicators import PowerIndicator
from unity8.indicators.tests import IndicatorTestCase
from unity8.indicators import wait_for_notification_dialog
from unity8 import process_helpers

class MockBattery(object):

    def __init__(self, proxy, object_path):
        self.proxy = proxy
        self.object_path = object_path

    def set_properties(self, properties):
        self.proxy.SetDeviceProperties(self.object_path, properties)


class MockUPower(Fixture):

    def setUp(self):

        super(MockUPower, self).setUp()

        self._battery_count = 0

        key = 'DBUS_SYSTEM_BUS_ADDRESS'
        if key in os.environ:
            raise OSError("environment variable {} already set".format(key))

        # start a dbusmock system bus and get its address, which looks like
        # "unix:abstract=/tmp/dbus-LQo4Do4ldY,guid=3f7f39089f00884fa96533f354935995"
        dbusmock.DBusTestCase.start_system_bus()
        self.bus_address = os.environ[key].split(',')[0]

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
        super(IndicatorPowerTestCase, self).setUp()

        # start a mock UPower service
        self.upower = self.useFixture(MockUPower())

        # restart indicator-power with the mock env variables
        self.start_test_service(
            'indicator-power',
            'INDICATOR_POWER_BUS_ADDRESS_UPOWER={}'.format(
                self.upower.bus_address
            )
        )

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

        indicator = PowerIndicator(self.main_window)

        for properties, expected in steps:
            battery.set_properties(properties)
            self.assertTrue(
                indicator.get_icon_name,
                Eventually(Contains(expected['icon_name']))
            )

class IndicatorPowerTestCase2(IndicatorTestCase):
    def setUp(self):
        super(IndicatorPowerTestCase2, self).setUp()

        # start a mock UPower service
        self.upower = self.useFixture(MockUPower())

        # restart indicator-power with the mock env variables
        self.start_test_service(
            'indicator-power',
            'INDICATOR_POWER_BUS_ADDRESS_UPOWER={}'.format(
                self.upower.bus_address
            )
        )

    def test111(self):
        battery = self.upower.add_discharging_battery()
        battery.set_properties({'Percentage': 3.0})

        n = wait_for_notification_dialog(self, timeout=10)
        print (n.get_data())

    def test1(self):
        command = [
            'python3',
            './unity8/shell/emulators/create_interactive_notification.py'
        ]
        p = subprocess.Popen(command)
        n = wait_for_notification_dialog(self, timeout=10)
        assertEqual(n.get_data()['summary'], 'Summary')
        assertEqual(n.get_data()['body'], 'Body')
        p.wait()
