# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright (C) 2013 Canonical Ltd
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

"""Reminders app autopilot tests."""

import os
import os.path
import logging

from autopilot.input import Mouse, Touch, Pointer
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase

from ubuntuuitoolkit import (
    base,
    emulators as toolkit_emulators
)

from reminders import emulators

logger = logging.getLogger(__name__)

class RemindersAppTestCase(AutopilotTestCase):
    """A common test case class that provides several useful methods for
       reminders-app tests."""

    if model() == 'Desktop':
        scenarios = [('with mouse', dict(input_device_class=Mouse))]
    else:
        scenarios = [('with touch', dict(input_device_class=Touch))]

    local_location_binary = "../../src/app/reminders"
    local_location_qml = "../../src/app/qml/reminders.qml"
    installed_location_binary= "/usr/bin/reminders"
    installed_location_qml = "/usr/share/reminders/qml/reminders.qml"

    def setUp(self):
        self.pointing_device = Pointer(self.input_device_class.create())
        super(RemindersAppTestCase, self).setUp()

        #turn off the OSK so it doesn't block screen elements
        if model() != 'Desktop':
            os.system("stop maliit-server")
            self.addCleanup(os.system, "start maliit-server")

        if os.path.exists(self.local_location_qml):
            self.launch_test_local()
        elif os.path.exists(self.installed_location_binary):
            self.launch_test_installed()
        else:
            self.launch_test_click()

    def launch_test_local(self):
        logger.debug("Launching via local")
        self.app = self.launch_test_application(
            self.local_location_binary,
            "-q " + self.local_location_qml,
            app_type='qt',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    def launch_test_installed(self):
        logger.debug("Launching via installation")
        self.app = self.launch_test_application(
            self.installed_location_binary,
            "-q " + self.installed_location_qml,
            "--desktop_file_hint=/usr/share/applications/"
            "reminders.desktop",
            app_type='qt',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)


    def launch_test_click(self):
        logger.debug("Launching via click")
        self.app = self.launch_click_package(
            "com.ubuntu.reminders-app",
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    @property
    def main_view(self):
        return self.app.select_single(emulators.MainView)
