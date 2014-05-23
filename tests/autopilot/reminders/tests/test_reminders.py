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
import uuid

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
        super(RemindersTestCaseWithAccount, self).setUp()
        no_account_dialog = self.app.main_view.no_account_dialog
        self.add_evernote_account()
        no_account_dialog.wait_until_destroyed()

    def add_evernote_account(self):
        account_manager = credentials.AccountManager()
        oauth_token = (
            'S=s1:U=8e6bf:E=14d08e375ff:C=145b1324a03:P=1cd:A=en-devtoken:'
            'V=2:H=79b946c32b4515ee52b387f7b68baa69')
        account = account_manager.add_evernote_account(
            'dummy', 'dummy', oauth_token)
        self.addCleanup(account_manager.delete_account, account)
        del account_manager._manager
        del account_manager

    def test_add_notebook_must_append_it_to_list(self):
        test_notebook_title = 'Test notebook {}'.format(uuid.uuid1())

        notebooks_page = self.app.open_notebooks()
        # FIXME delete the added notebook. Otherwise, the test account will
        # fill up. See http://pad.lv/1318749 --elopio - 2014-05-12
        notebooks_page.add_notebook(test_notebook_title)

        last_notebook = notebooks_page.get_notebooks()[-1]
        # TODO there's a bug with the last updated value: http://pad.lv/1318751
        # so we can't check the full tuple. Uncomment this as soon as the bug
        # is fixed. --elopio - 2014-05-12
        #self.assertEqual(
        #    last_notebook,
        #    (test_notebook_title, 'Last edited today', 'Private', 0))
        self.assertEqual(last_notebook[0], test_notebook_title)
        self.assertEqual(last_notebook[2], 'Private')
        self.assertEqual(last_notebook[3], 0)
