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
from evernote.edam.error import ttypes as evernote_errors
from testtools.matchers import Equals

import reminders
from reminders import credentials, evernote, fixture_setup, tests


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

        # self.app.main_view.no_account_dialog.open_account_settings()
        button = self.app.main_view.select_single(
            'Button', objectName='openAccountButton')
        self.app.main_view.pointing_device.click_object(button)

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
        # bug https://bugs.launchpad.net/reminders-app/+bug/1347905
        if platform.model() != 'Desktop':
            self.skipTest("Fake Account failure bug 1347905")
        super(RemindersTestCaseWithAccount, self).setUp()
        no_account_dialog = self.app.main_view.no_account_dialog
        self.add_evernote_account()
        logger.info('Waiting for the Evernote account to be created.')
        no_account_dialog.wait_until_destroyed()
        self.evernote_client = evernote.SandboxEvernoteClient()

    def add_evernote_account(self):
        account_manager = credentials.AccountManager()
        account = account_manager.add_evernote_account(
            'dummy', 'dummy', evernote.TEST_OAUTH_TOKEN)
        self.addCleanup(account_manager.delete_account, account)
        del account_manager._manager
        del account_manager

    def expunge_test_notebook(self, notebook_name):
        try:
            self.evernote_client.expunge_notebook_by_name(notebook_name)
        except evernote_errors.EDAMNotFoundException:
            # The notebook was already deleted or not successfully created.
            pass

    def test_add_notebook_must_append_it_to_list(self):
        """Test that an added notebook will be available for selection."""
        test_notebook_title = 'Test notebook {}'.format(uuid.uuid1())
        self.addCleanup(self.expunge_test_notebook, test_notebook_title)

        notebooks_page = self.app.open_notebooks()
        notebooks_page.add_notebook(test_notebook_title)

        last_notebook = notebooks_page.get_notebooks()[-1]
        self.assertEqual(
            last_notebook,
            (test_notebook_title, 'Last edited today', 'Private', 0))

    def test_add_notebook_must_create_it_in_server(self):
        """Test that an added notebook will be created on the server."""
        test_notebook_title = 'Test notebook {}'.format(uuid.uuid1())
        self.addCleanup(self.expunge_test_notebook, test_notebook_title)

        notebooks_page = self.app.open_notebooks()
        notebooks_page.add_notebook(test_notebook_title)

        # An exception will be raised if the notebook is note found.
        self.evernote_client.get_notebook_by_name(test_notebook_title)
