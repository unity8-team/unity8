# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright (C) 2013, 2014 Canonical Ltd
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

"""Reminders app autopilot tests."""

from __future__ import absolute_import

import logging

from autopilot import platform
from autopilot.matchers import Eventually
from testtools.matchers import Equals

import reminders
from reminders import credentials, fixture_setup, tests


logger = logging.getLogger(__name__)


class RemindersTestCaseWithoutAccount(tests.RemindersAppTestCase):

    def test_open_application_without_account(self):
        """Test that the No account dialog is visible."""
        self.assertTrue(self.app.main_view.no_account_dialog.visible)

    def test_go_to_account_settings(self):
        """Test that the Go to account settings button calls url-dispatcher."""
        if platform.model() == 'Desktop':
             self.skipTest("URL dispatcher doesn't work on the desktop.")
        url_dispatcher = fixture_setup.FakeURLDispatcher()
        self.useFixture(url_dispatcher)

        self.app.main_view.no_account_dialog.open_account_settings()

        def get_last_dispatch_url_call_parameter():
            # Workaround for http://pad.lv/1312384
            try:
                return url_dispatcher.get_last_dispatch_url_call_parameter()
            except reminders.RemindersAppException:
                return None

        self.assertThat(
            get_last_dispatch_url_call_parameter,
            Eventually(Equals('settings:///system/online-accounts')))


class RemindersTestCaseWithAccount(tests.RemindersAppTestCase):

    def setUp(self):
        self.add_evernote_credentials()
        super(RemindersTestCaseWithAccount, self).setUp()

    def add_evernote_credentials(self):
        account_manager = credentials.AccountManager()
        account = account_manager.add_evernote_credentials(
            'u1test@canonical.com', 'password')
        self.addCleanup(account_manager.delete_account, account)

    def testopen_application_with_account(self):
        """Test that the No account dialog is not visible."""
        self.assertFalse(self.app.main_view.no_account_dialog.visible)
