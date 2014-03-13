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

from reminders_app import emulators

logger = logging.getLogger(__name__)


def get_module_include_path():
    return os.path.abspath(
        os.path.join(
            os.path.dirname(__file__),
            '..',
            '..',
            '..',
            '..',
            'builddir/src/plugin/Evernote')
        )


class RemindersAppTestCase(AutopilotTestCase):
    """A common test case class that provides several useful methods for
       reminders-app tests."""

    if model() == 'Desktop':
        scenarios = [('with mouse', dict(input_device_class=Mouse))]
    else:
        scenarios = [('with touch', dict(input_device_class=Touch))]

    local_location = "../../src/app/qml/reminders.qml"
    installed_location = "/usr/share/reminders/qml/reminders.qml"

    def setUp(self):
        self.pointing_device = Pointer(self.input_device_class.create())
        super(RemindersAppTestCase, self).setUp()

        #turn off the OSK so it doesn't block screen elements
        if model() != 'Desktop':
            os.system("stop maliit-server")
            #adding cleanup step seems to restart service immeadiately
            #disabling for now
            #self.addCleanup(os.system("start maliit-server"))

        #if os.path.exists(self.local_location):
            #self.launch_test_local()
        #elif os.path.exists(self.installed_location):
            #self.launch_test_installed()
        #else:
            #self.launch_test_click()

        if os.path.exists(self.installed_location):
            self.launch_test_installed()
        else:
            self.launch_test_click()

    def launch_test_local(self):
        self.app = self.launch_test_application(
            base.get_qmlscene_launch_command(),
            "-I", get_module_include_path(),
            self.local_location,
            "--desktop_file_hint=/home/phablet/reminders/"
            "reminders-app.desktop",
            app_type='qt',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    def launch_test_installed(self):
        self.app = self.launch_test_application(
            base.get_qmlscene_launch_command(),
            self.installed_location,
            "--desktop_file_hint=/usr/share/applications/"
            "reminders.desktop",
            app_type='qt',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    def launch_test_click(self):
        self.app = self.launch_click_package(
            "com.ubuntu.reminders-app",
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    @property
    def main_view(self):
        return self.app.select_single(emulators.MainView)
