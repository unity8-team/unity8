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

from unity8 import process_helpers
from unity8.shell.tests import (
    UnityTestCase,
    _get_device_emulation_scenarios,
)


class IndicatorTestCase(UnityTestCase):

    scenarios = _get_device_emulation_scenarios()

    def setUp(self):
        super(IndicatorTestCase, self).setUp()
        self._dirty_services = set()
        self.unity_proxy = self.launch_unity()
        process_helpers.unlock_unity(self.unity_proxy)

    def start_test_service(self, service_name, *args):
        """Restart a service (e.g. 'indicator-power-service') with test args.

        Adds a no-arguments restart to addCleanup() so that the system
        can reset to a nontest version of the service when the tests finish.
        """
        self._start_service(service_name, *args)
        if service_name not in self._dirty_services:
            self._dirty_services.add(service_name)
            self.addCleanup(self._start_service, service_name)

    @staticmethod
    def _start_service(service_name, *args):
        """Restart an upstart service; e.g. indicator-power-service"""
        if process_helpers.is_job_running(service_name):
            process_helpers.stop_job(service_name)
        process_helpers.start_job(service_name, *args)
