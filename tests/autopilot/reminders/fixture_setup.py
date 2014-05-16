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


import fixtures

from reminders import fake_services


class FakeURLDispatcher(fixtures.Fixture):

    def setUp(self):
        super(FakeURLDispatcher, self).setUp()
        self.fake_service = fake_services.FakeURLDispatcherService()
        self.addCleanup(self.fake_service.stop)
        self.fake_service.start()

    def get_last_dispatch_url_call_parameter(self):
        return self.fake_service.get_last_dispatch_url_call_parameter()
