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

"""Test for the Launcher."""

from autopilot import platform
from autopilot.matchers import Eventually
from testtools import skipIf
from testtools.matchers import Equals

from unity8 import process_helpers
from unity8.shell import tests, fixture_setup, disable_qml_mocking


@skipIf(
    platform.model() == 'Desktop',
    'Needs platform APIs not available on desktop, yet.'
)
class LauncherTestCase(tests.UnityTestCase):

    def setUp(self):
        self.useFixture(fixture_setup.LauncherIcon())
        super(LauncherTestCase, self).setUp()

    @disable_qml_mocking
    def test_launcher_opens_app(self):
        """Make sure apps start from the launcher."""
        self.unity_proxy = self.launch_unity()
        process_helpers.unlock_unity(self.unity_proxy)

        launcher = self.main_window.get_launcher()
        launcher.show()
        launcher.tap_icon('launcherDelegate0')

        self.assertThat(
            self.main_window.get_current_focused_app_id,
            Eventually(Equals('messaging-app'))
        )
