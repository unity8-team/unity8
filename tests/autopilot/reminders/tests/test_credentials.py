# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright (C) 2014 Canonical Ltd
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

import logging

from gi.repository import Accounts
from testtools.matchers import HasLength

from reminders import credentials, evernote, tests


logger = logging.getLogger(__name__)


class EvernoteCredentialsTestCase(tests.BaseTestCaseWithTempHome):

    def setUp(self):
        # bug https://bugs.launchpad.net/reminders-app/+bug/1347905
        if platform.model() != 'Desktop':
            self.skipTest("Fake Account failure bug 1347905")
        super(EvernoteCredentialsTestCase, self).setUp()
        self.account_manager = credentials.AccountManager()

    def add_evernote_account(self):
        account = self.account_manager.add_evernote_account(
            'dummy', 'dummy', evernote.TEST_OAUTH_TOKEN)
        self.addCleanup(self.delete_account_and_manager, account)
        return account

    def delete_account_and_manager(self, account):
        if account.id in self.account_manager._manager.list():
            self.account_manager.delete_account(account)
        del self.account_manager._manager
        del self.account_manager

    def test_add_evernote_account_must_enable_it(self):
        account = self.add_evernote_account()

        self.assertTrue(account.get_enabled())

    def test_add_evernote_account_must_set_provider(self):
        account = self.add_evernote_account()

        self.assertEqual(account.get_provider_name(), 'evernote-sandbox')

    def test_add_evernote_account_must_enable_evernote_service(self):
        account = self.add_evernote_account()
        services = account.list_services()

        self.assertThat(services, HasLength(1))
        self.assertEqual(services[0].get_name(), 'evernote-sandbox')
        service = Accounts.AccountService.new(account, services[0])
        self.assertTrue(service.get_enabled())

    def test_delete_evernote_account_must_remove_it(self):
        account = self.add_evernote_account()
        self.assertThat(self.account_manager._manager.list(), HasLength(1))

        self.account_manager.delete_account(account)
        self.assertThat(self.account_manager._manager.list(), HasLength(0))
