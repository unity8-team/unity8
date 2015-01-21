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
        super().setUp()
        self._dirty_services = set()
        self.unity_proxy = self.launch_unity()
        unlock_unity(self.unity_proxy)

    def restart_service(self, service_name, args):
        """
        Restart a service with the specified args
        and ensure there's a cleanup task to restart it w/o args.
        """
        try:
            self._initctl_restart(service_name, args)
        finally:
            if service_name not in self._dirty_services:
                self._dirty_services.add(service_name)
                self.addCleanup(self._initctl_restart, service_name)

    @staticmethod
    def _initctl_restart(service_name, args=[]):
        """initctl restart service of given name."""
        # nb: since we're trying to change the job's configuratoin,
        # we must stop + start here, rather than "initctl restart"
        subprocess.check_call(['initctl', 'stop', service_name])
        subprocess.check_call(['initctl', 'start', service_name] + args)
