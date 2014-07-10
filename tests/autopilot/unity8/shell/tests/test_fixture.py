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

from unity8.shell import tests, fixture_setup
from unity8 import process_helpers


class TestFixture(tests.UnityTestCase):

    def setUp(self):
        launcher_icon = fixture_setup.LauncherIcon()
        self.useFixture(launcher_icon)
        super(TestFixture, self).setUp()

    def test_launcher_icon_fixture_is_working(self):
        """Ensure launcher icon fixture works and messaging-app
        is the only icon in the launcher.
        """
        unity_proxy = self.launch_unity()

        launcher_icons = self.main_window.get_number_of_launcher_icons()
        self.assertEquals(launcher_icons, 1)

        self.assertIsNotNone(
            self.main_window.get_launcher_icon_by_id('messaging-app'))
