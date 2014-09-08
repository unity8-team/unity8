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

import json
import logging
import os
import tempfile
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
            launcher = self.launch_ubuntu_app
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
            'com.ubuntu.reminders.desktop',
            app_type='qt',
            emulator_base=ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase)

    @autopilot_logging.log_action(logger.info)
    def launch_ubuntu_app(self):
        desktop_file_path = self.write_sandbox_desktop_file()
        desktop_file_name = os.path.basename(desktop_file_path)
        application_name, _ = os.path.splitext(desktop_file_name)
        return self.launch_upstart_application(
            application_name,
            emulator_base=ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase)

    def write_sandbox_desktop_file(self):
        desktop_file_dir = self.get_local_desktop_file_directory()
        desktop_file = self.get_named_temporary_file(
            suffix='.desktop', dir=desktop_file_dir)
        desktop_file.write('[Desktop Entry]\n')
        version, installed_path = self.get_installed_version_and_directory()
        reminders_sandbox_exec = (
            'aa-exec-click -p com.ubuntu.reminders_reminders_{}'
            ' -- reminders -s'.format(version))
        desktop_file_dict = {
            'Type': 'Application',
            'Name': 'reminders',
            'Exec': reminders_sandbox_exec,
            'Icon': 'Not important',
            'Path': installed_path
        }
        for key, value in desktop_file_dict.items():
            desktop_file.write('{key}={value}\n'.format(key=key, value=value))
        desktop_file.close()
        return desktop_file.name

    def get_local_desktop_file_directory(self):
        return os.path.join(
            os.environ.get('HOME'), '.local', 'share', 'applications')

    def get_named_temporary_file(self, dir=None, mode='w+t',
        delete=False, suffix=''):
        # Discard files with underscores which look like an APP_ID to Unity
        # See https://bugs.launchpad.net/ubuntu-ui-toolkit/+bug/1329141
        chars = tempfile._RandomNameSequence.characters.strip("_")
        tempfile._RandomNameSequence.characters = chars
        return tempfile.NamedTemporaryFile(dir=dir, mode=mode,
        delete=delete, suffix=suffix)

    def get_installed_version_and_directory(self):
        for package in self.get_click_manifest():
            if package['name'] == 'com.ubuntu.reminders':
                return package['version'], package['_directory']

    def get_click_manifest(self):
        """Return the click package manifest as a python list."""
        # XXX This is duplicated from autopilot. We need to find a better place
        # to put helpers for click. --elopio - 2014-09-08
        # get the whole click package manifest every time - it seems fast
        # enough but this is a potential optimisation point for the future:
        click_manifest_str = subprocess.check_output(
            ["click", "list", "--manifest"], universal_newlines=True)
        return json.loads(click_manifest_str)

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
