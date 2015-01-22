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


class PowerIndicator(object):

    def __init__(self, main_window):
        self.main_window = main_window

    def get_icon_name(self):
        """Returns the icon name.

        Can be a list of options, eg
        'image://theme/battery-040,battery-good-symbolic,battery-good'
        """
        widget = self.main_window.wait_select_single(
            objectName='indicator-power-widget'
        )
        # convert it from a dbus.string to a normal string
        return str(widget.icons[0])
