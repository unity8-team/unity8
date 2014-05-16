# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright (C) 2013, 2014 Canonical Ltd.
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

"""Reminders app tests and emulators - top level package."""

import logging
from distutils import version

import autopilot
from autopilot import logging as autopilot_logging
from autopilot.introspection import dbus
from ubuntuuitoolkit import emulators as toolkit_emulators


logger = logging.getLogger(__name__)


class RemindersAppException(Exception):
    """Exception raised when there's an error in the Reminders App."""


class RemindersApp(object):
    """Autopilot helper object for the Reminders application."""

    def __init__(self, app_proxy):
        self.app = app_proxy
        self.main_view = self.app.select_single(MainView)


class MainView(toolkit_emulators.MainView):
    """Autopilot custom proxy object for the MainView."""

    def __init__(self, *args):
        super(MainView, self).__init__(*args)
        self.visible.wait_for(True)
        try:
            self._no_account_dialog = self.select_single(
                objectName='noAccountDialog')
        except dbus.StateNotFoundError:
            self._no_account_dialog = None

    @property
    def no_account_dialog(self):
        if self._no_account_dialog is None:
            raise RemindersAppException(
                'The No Account dialog is not present')
        else:
            return self._no_account_dialog


class NoAccountDialog(toolkit_emulators.UbuntuUIToolkitEmulatorBase):

    @classmethod
    def validate_dbus_object(cls, path, state):
        if (version.LooseVersion(autopilot.version) >=
                version.LooseVersion('1.5')):
            # TODO there's an autopilot branch that will put the function in a
            # public module. Update this once the branch is released.
            # --elopio - 2014-05-16
            from autopilot.introspection import _xpathselect
            name = _xpathselect.get_classname_from_path(path)
        else:
            name = dbus.get_classname_from_path(path)
        if name == 'Dialog':
            if 'noAccountDialog' == state['objectName'][1]:
                return True
        return False

    @autopilot_logging.log_action(logger.info)
    def open_account_settings(self):
        button = self.select_single('Button', objectName='openAccountButton')
        self.pointing_device.click_object(button)
