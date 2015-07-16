# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Unity Autopilot Test Suite
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
#

"""Tests for the session container"""

from testtools.matchers import Equals
from ubuntuuitoolkit import ubuntu_scenarios

from unity8.process_helpers import unlock_unity
from unity8.shell.tests import UnityTestCase

import logging

logger = logging.getLogger(__name__)


class SessionContainerTests(UnityTestCase):

    def test_number_of_sessions(self):
        self.launch_unity()
        unlock_unity()
        num_sessions = self.main_window.get_number_of_sessions()
        self.assertThat(num_sessions, Equals(1))


