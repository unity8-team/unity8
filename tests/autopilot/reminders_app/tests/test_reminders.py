# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Reminders app autopilot tests."""

from __future__ import absolute_import

from autopilot.matchers import Eventually
from testtools.matchers import Is, Not, Equals

from reminders_app.tests import RemindersAppTestCase

import unittest
import logging
from time import sleep

logger = logging.getLogger(__name__)


class TestMainWindow(RemindersAppTestCase):

    def setUp(self):
        super(TestMainWindow, self).setUp()

        self.assertThat(self.main_view.visible, Eventually(Equals(True)))

    def test_logon_to_Evernote(self):
        # Click on existing Evernote account
        # (the account must have be added before running tests)
        Evernoteaccount = self.main_view.get_evernote_account()
        accountselectorPage = self.main_view.get_accountselectorpage()
        self.assertThat(accountselectorPage.visible, Eventually(Equals(True)))

        self.pointing_device.click_object(Evernoteaccount)

        # verify we are logged on
        notesTab = self.main_view.switch_to_tab("NotesTab")
        self.assertThat(notesTab.visible, Eventually(Equals(True)))
