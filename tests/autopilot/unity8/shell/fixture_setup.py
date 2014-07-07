# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Unity Autopilot Test Suite
# Copyright (C) 2014 Canonical
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
#

"""Set up and clean up fixtures for the Unity acceptance tests."""

import dbus
import os
import subprocess
import sysconfig

import fixtures

import unity8


class FakeScopes(fixtures.Fixture):

    def setUp(self):
        super(FakeScopes, self).setUp()
        self.useFixture(
            fixtures.EnvironmentVariable(
                'QML2_IMPORT_PATH',
                newvalue=self._get_fake_scopes_library_path()))

    def _get_fake_scopes_library_path(self):
        if unity8.running_installed_tests():
            mock_path = 'qml/scopefakes/'
        else:
            mock_path = os.path.join(
                '../lib/', sysconfig.get_config_var('MULTIARCH'),
                'unity8/qml/scopefakes/')
        lib_path = unity8.get_lib_path()
        ld_library_path = os.path.abspath(os.path.join(lib_path, mock_path))

        if not os.path.exists(ld_library_path):
            raise RuntimeError(
                'Expected library path does not exists: %s.' % (
                    ld_library_path))
        return ld_library_path


class LauncherIcon(fixtures.Fixture):
    """Fixture to setup launcher icons."""

    def setUp(self):
        super(LauncherIcon, self).setUp()
        self._add_messaging_app_icon_to_launcher()

    def _get_accounts_service_dbus_iface(self):
        bus = dbus.SystemBus()
        proxy = bus.get_object(
            'org.freedesktop.Accounts',
            '/org/freedesktop/Accounts/User32011')
        return dbus.Interface(proxy, 'org.freedesktop.DBus.Properties')

    def _backup_launcher_icons(self):
        manager = self._get_accounts_service_dbus_iface()
        self.backup = manager.Get(
            'com.canonical.unity.AccountsService',
            'launcher-items')
        self.addCleanup(self._set_launcher_icons, self.backup)

    def _set_launcher_icons(self, icons_config):
        manager = self._get_accounts_service_dbus_iface()
        self.backup = manager.Set(
            'com.canonical.unity.AccountsService',
            'launcher-items', icons_config)

    def _add_messaging_app_icon_to_launcher(self):
        self._backup_launcher_icons()

        messaging_icon = dbus.Array([dbus.Dictionary({
        dbus.String('count'): dbus.Int32(0, variant_level=1),
        dbus.String('countVisible'): dbus.Boolean(False, variant_level=1),
        dbus.String('name'): dbus.String('Messaging', variant_level=1),
        dbus.String('id'): dbus.String('messaging-app', variant_level=1),
        dbus.String('icon'): dbus.String('image://theme/messaging-app',
            variant_level=1)},
        signature=dbus.Signature('sv'))],
        signature=dbus.Signature('a{sv}'),
        variant_level=1)
        
        self._set_launcher_icons(messaging_icon)
