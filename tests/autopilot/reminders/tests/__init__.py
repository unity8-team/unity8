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

import logging
import os
import shutil
import subprocess

import fixtures
from autopilot import logging as autopilot_logging
from autopilot.testcase import AutopilotTestCase
import ubuntuuitoolkit
from ubuntuuitoolkit import fixture_setup as toolkit_fixtures

import reminders

logger = logging.getLogger(__name__)


class BaseTestCaseWithTempHome(AutopilotTestCase):

    """Base test case that patches the home directory.

    That way we start the tests with a clean environment.

    """

    local_location = os.path.dirname(os.path.dirname(os.getcwd()))

    local_location_qml = os.path.join(
        local_location, 'src/app/qml/reminders.qml')
    local_location_binary = os.path.join(local_location, 'src/app/reminders')
    installed_location_binary = '/usr/bin/reminders'
    installed_location_qml = '/usr/share/reminders/qml/reminders.qml'

    def setUp(self):
        self.kill_signond()
        self.addCleanup(self.kill_signond)
        super(BaseTestCaseWithTempHome, self).setUp()
        _, test_type = self.get_launcher_method_and_type()
        self.home_dir = self._patch_home(test_type)

    def kill_signond(self):
        # We kill signond so it's restarted using the temporary HOME. Otherwise
        # it will remain running until it has 5 seconds of inactivity, keeping
        # reference to other directories.
        subprocess.call(['pkill', '-9', 'signond'])

    def get_launcher_method_and_type(self):
        if os.path.exists(self.local_location_binary):
            launcher = self.launch_test_local
            test_type = 'local'
        elif os.path.exists(self.installed_location_binary):
            launcher = self.launch_test_installed
            test_type = 'deb'
        else:
            launcher = self.launch_test_click
            test_type = 'click'
        return launcher, test_type

    @autopilot_logging.log_action(logger.info)
    def launch_test_local(self):
        self.useFixture(fixtures.EnvironmentVariable(
            'QML2_IMPORT_PATH',
            newvalue=os.path.join(self.local_location, 'src/plugin')))
        return self.launch_test_application(
            self.local_location_binary,
            '-q', self.local_location_qml,
            '-s',
            app_type='qt',
            emulator_base=ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase)

    @autopilot_logging.log_action(logger.info)
    def launch_test_installed(self):
        return self.launch_test_application(
            self.installed_location_binary,
            '-q ' + self.installed_location_qml,
            '-s',
            '--desktop_file_hint=/usr/share/applications/'
            'reminders.desktop',
            app_type='qt',
            emulator_base=ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase)

    @autopilot_logging.log_action(logger.info)
    def launch_test_click(self):
        return self.launch_click_package(
            'com.ubuntu.reminders',
            '-s',
            emulator_base=ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase)

    def _patch_home(self, test_type):
        temp_dir_fixture = fixtures.TempDir()
        self.useFixture(temp_dir_fixture)
        temp_dir = temp_dir_fixture.path
        temp_xdg_config_home = os.path.join(temp_dir, '.config')

        # If running under xvfb, as jenkins does,
        # xsession will fail to start without xauthority file
        # Thus if the Xauthority file is in the home directory
        # make sure we copy it to our temp home directory
        self._copy_xauthority_file(temp_dir)

        # click requires using initctl env (upstart), but the desktop can set
        # an environment variable instead
        if test_type == 'click':
            self.useFixture(
                toolkit_fixtures.InitctlEnvironmentVariable(
                    HOME=temp_dir, XDG_CONFIG_HOME=temp_xdg_config_home))
        else:
            self.useFixture(
                fixtures.EnvironmentVariable('HOME', newvalue=temp_dir))
            self.useFixture(
                fixtures.EnvironmentVariable(
                    'XDG_CONFIG_HOME',  newvalue=temp_xdg_config_home))

        logger.debug('Patched home to fake home directory ' + temp_dir)

        return temp_dir

    def _copy_xauthority_file(self, directory):
        """Copy .Xauthority file to directory, if it exists in /home."""
        xauth = os.path.expanduser(os.path.join('~', '.Xauthority'))
        if os.path.isfile(xauth):
            logger.debug("Copying .Xauthority to " + directory)
            shutil.copyfile(
                os.path.expanduser(os.path.join('~', '.Xauthority')),
                os.path.join(directory, '.Xauthority'))


class RemindersAppTestCase(BaseTestCaseWithTempHome):

    """Base test case that launches the reminders-app."""

    def setUp(self):
        super(RemindersAppTestCase, self).setUp()
        launcher_method, _ = self.get_launcher_method_and_type()
        self.app = reminders.RemindersApp(launcher_method())
