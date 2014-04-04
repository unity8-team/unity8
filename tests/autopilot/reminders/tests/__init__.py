# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright (C) 2013, 2014 Canonical Ltd.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

"""Reminders app autopilot tests."""

import os
import os.path
import logging

import fixtures
from autopilot import logging as autopilot_logging
from autopilot.input import Mouse, Touch, Pointer
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase
from ubuntuuitoolkit import emulators as toolkit_emulators

import reminders

logger = logging.getLogger(__name__)


class RemindersAppTestCase(AutopilotTestCase):
    """A common test case class that provides several useful methods for
       reminders-app tests."""

    if model() == 'Desktop':
        scenarios = [('with mouse', dict(input_device_class=Mouse))]
    else:
        scenarios = [('with touch', dict(input_device_class=Touch))]

    local_location_binary = '../../src/app/reminders'
    installed_location_binary = '/usr/bin/reminders'
    installed_location_qml = '/usr/share/reminders/qml/reminders.qml'

    def setUp(self):
        self.pointing_device = Pointer(self.input_device_class.create())
        super(RemindersAppTestCase, self).setUp()

        if os.path.exists(self.local_location_binary):
            app_proxy = self.launch_test_local()
        elif os.path.exists(self.installed_location_binary):
            app_proxy = self.launch_test_installed()
        else:
            app_proxy = self.launch_test_click()

        self.app = reminders.RemindersApp(app_proxy)

    @autopilot_logging.log_action(logger.info)
    def launch_test_local(self):
        self.useFixture(fixtures.EnvironmentVariable(
            'QML2_IMPORT_PATH', newvalue='../../src/plugin'))
        return self.launch_test_application(
            self.local_location_binary,
            app_type='qt',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    @autopilot_logging.log_action(logger.info)
    def launch_test_installed(self):
        return self.launch_test_application(
            self.installed_location_binary,
            '-q ' + self.installed_location_qml,
            '--desktop_file_hint=/usr/share/applications/'
            'reminders.desktop',
            app_type='qt',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    @autopilot_logging.log_action(logger.info)
    def launch_test_click(self):
        return self.launch_click_package(
            'com.ubuntu.reminders-app',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)
