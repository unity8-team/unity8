# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright (C) 2014 Canonical Ltd.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

import logging
import threading

from gi.repository import Accounts, GLib, Signon


logger = logging.getLogger(__name__)


class CredentialsException(Exception):
    """Exception for credentials problems."""


class AccountManager(object):
    """Manager for online accounts."""

    def __init__(self):
        self._manager = Accounts.Manager.new()

    def _start_main_loop(self):
        self.error = None
        self._main_loop = GLib.MainLoop()
        self._main_loop_thread = threading.Thread(
            target=self._main_loop.run)
        self._main_loop_thread.start()

    def _join_main_loop(self):
        self._main_loop_thread.join()
        if self.error is not None:
            raise CredentialsException(self.error.message)

    def add_evernote_account(self, user_name, password, oauth_token):
        """Add an evernote account.

        :param user_name: The user name of the account.
        :param password: The password of the account.
        :param oauth_token: The oauth token of the account.

        """
        logger.debug('Add an evernote account.')
        self._start_main_loop()

        account = self._create_account()

        info = self._get_identity_info(user_name, password)

        identity = Signon.Identity.new()
        identity.store_credentials_with_info(
            info, self._set_credentials_id_to_account,
            {'account': account, 'oauth_token': oauth_token})

        self._join_main_loop()

        self._enable_evernote_service(account)

        return account

    def _create_account(self):
        logger.debug('Creating the Evernote account.')
        account = self._manager.create_account('evernote')
        account.set_enabled(True)
        account.store(self._on_account_created, None)
        return account

    def _on_account_created(self, account, error, _):
        if error:
            self._quit_main_loop_on_error(error, 'storing account')

    def _quit_main_loop_on_error(self, error, step):
        logger.error('Error {}.'.format(step))
        self.error = error
        self._main_loop.quit()

    def _get_identity_info(self, user_name, password):
        info = Signon.IdentityInfo.new()
        info.set_username(user_name)
        info.set_caption(user_name)
        info.set_secret(password, True)
        return info

    def _set_credentials_id_to_account(
            self, identity, id_, error, account_dict):
        if error:
            self._quit_main_loop_on_error(
                error, 'storing credentials with info')

        logger.debug('Setting credentials to account.')
        account = account_dict.get('account')
        oauth_token = account_dict.get('oauth_token')
        account.set_variant('CredentialsId', GLib.Variant('u', id_))
        account.store(self._process_session, oauth_token)

    def _process_session(self, account, error, oauth_token):
        if error:
            self._quit_main_loop_on_error(
                error, 'setting credentials id to account')

        logger.debug('Processing session.')
        account_service = Accounts.AccountService.new(account, None)
        auth_data = account_service.get_auth_data()
        identity = auth_data.get_credentials_id()
        method = auth_data.get_method()
        mechanism = auth_data.get_mechanism()
        session_data = auth_data.get_parameters()
        session_data['ProvidedTokens'] = GLib.Variant('a{sv}', {
            'TokenSecret': GLib.Variant('s', 'dummy'),
            'AccessToken': GLib.Variant('s', oauth_token),
        })
        session = Signon.AuthSession.new(identity, method)
        session.process(
            session_data, mechanism, self._on_login_processed, None)

    def _on_login_processed(self, session, reply, error, userdata):
        if error:
            self._quit_main_loop_on_error(error, 'processing session')

        else:
            self._main_loop.quit()

    def _enable_evernote_service(self, account):
        logger.debug('Enabling evernote service.')
        service = self._manager.get_service('evernote')
        account.select_service(service)
        account.set_enabled(True)
        account.store(self._on_service_enabled, None)

    def _on_service_enabled(self, account, error, _):
        if error:
            self._quit_main_loop_on_error(error, 'enabling service')

    def delete_account(self, account):
        """Delete an account.

        :param account: The account to delete.

        """
        logger.info('Deleting the Evernote account.')
        self._start_main_loop()
        account.delete()
        account.store(self._on_account_deleted, None)
        self._join_main_loop()

    def _on_account_deleted(self, account, error, _):
        if error:
            self._quit_main_loop_on_error(error, 'deleting account')
        else:
            self._main_loop.quit()
