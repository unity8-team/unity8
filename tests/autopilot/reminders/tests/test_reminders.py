# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Reminders app autopilot tests."""

from __future__ import absolute_import

from autopilot.matchers import Eventually
from testtools.matchers import Equals, GreaterThan

from reminders.tests import RemindersAppTestCase

import logging

logger = logging.getLogger(__name__)


class TestMainWindow(RemindersAppTestCase):

    def setUp(self):
        super(TestMainWindow, self).setUp()

        self.assertThat(self.main_view.visible, Eventually(Equals(True)))

    def test_blank(setup):
        #jenkins requires at least one test
        return 0

