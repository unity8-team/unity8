# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Unity - Indicators Autopilot Test Suite
# Copyright (C) 2013, 2014 Canonical
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


import os
import subprocess

from autopilot import platform

from unity8.process_helpers import unlock_unity
from unity8.shell.tests import UnityTestCase, _get_device_emulation_scenarios


class IndicatorTestCase(UnityTestCase):

    device_emulation_scenarios = _get_device_emulation_scenarios()

    def setUp(self):
        # mysteriously disappeared from unity7, may need upstreaming
        if platform.model() == 'Desktop' and 'GRID_UNIT_PX' not in os.environ:
            os.environ['GRID_UNIT_PX'] = '13'
        super(IndicatorTestCase, self).setUp()
        self.unity_proxy = self.launch_unity()
        unlock_unity(self.unity_proxy)

    @staticmethod
    def initctl_set_env(variable, value):
        """initctl set-env to set the environmnent variable to given value."""
        subprocess.call(
            ['initctl', 'set-env', '-g', '{}={}'.format(variable, value)]
        )

    @staticmethod
    def initctl_unset_env(variable):
        """initctl unset-env to unset the environmnent variable."""
        subprocess.call(
            ['initctl', 'unset-env', '-g', '{}'.format(variable)]
        )

    @staticmethod
    def initctl_restart(service_name):
        """initctl restart service of given name."""
        subprocess.call(['initctl', 'restart', service_name])

