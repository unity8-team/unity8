# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright (C) 2014 Canonical Ltd.
#
# This file is part of reminders
#
# reminders is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 3.
#
# reminders is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import subprocess

import dbus
import dbusmock

import reminders


class FakeURLDispatcherService(object):
    """Fake URL Dispatcher service using a dbusmock interface."""

    def __init__(self):
        super(FakeURLDispatcherService, self).__init__()
        self.dbus_connection = dbusmock.DBusTestCase.get_dbus(system_bus=False)

    def start(self):
        # Stop the real url-dispatcher.
        subprocess.call(['initctl', 'stop', 'url-dispatcher'])
        self.dbus_mock_server = dbusmock.DBusTestCase.spawn_server(
            'com.canonical.URLDispatcher',
            '/com/canonical/URLDispatcher',
            'com.canonical.URLDispatcher',
            system_bus=False,
            stdout=subprocess.PIPE)
        self.mock = self._get_mock_interface()
        self.mock.AddMethod(
            'com.canonical.URLDispatcher', 'DispatchURL', 's', '', '')

    def _get_mock_interface(self):
        return dbus.Interface(
            self.dbus_connection.get_object(
                'com.canonical.URLDispatcher', '/com/canonical/URLDispatcher'),
            dbusmock.MOCK_IFACE)

    def stop(self):
        self.dbus_mock_server.terminate()
        self.dbus_mock_server.wait()

    def get_last_dispatch_url_call_parameter(self):
        calls = self.mock.GetCalls()
        if len(calls) == 0:
            raise reminders.RemindersAppException(
                'URL Dispatcher was not called.')
        last_call = self.mock.GetCalls()[-1]
        return last_call[2][0]
