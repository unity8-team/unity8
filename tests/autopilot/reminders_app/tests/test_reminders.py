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

from reminders_app.tests import RemindersAppTestCase

import logging

logger = logging.getLogger(__name__)


class TestMainWindow(RemindersAppTestCase):

    def setUp(self):
        super(TestMainWindow, self).setUp()

        self.assertThat(self.main_view.visible, Eventually(Equals(True)))

    def test_download_list_of_notebooks(self):
        """test to check whether downloading a list from Notebooks from
           Evernote is successful or not """
        #Evernoteaccount = self.main_view.get_evernote_account()
        #self.pointing_device.click_object(Evernoteaccount)

        notebookTab = self.main_view.switch_to_tab("NotebookTab")
        self.assertThat(notebookTab.visible, Eventually(Equals(True)))

        notebookslistview = self.main_view.get_notespageListview()
        self.assertThat(notebookslistview.count,  Eventually(GreaterThan(0)))

