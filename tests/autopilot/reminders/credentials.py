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


import threading

from gi.repository import Accounts, GLib, Signon


class CredentialsException(Exception):
    """Exception for credentials problems."""


class AccountManager(object):

    def __init__(self):
        self._manager = Accounts.Manager()

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

    def add_evernote_credentials(self, user_name, password):
        self._start_main_loop()

        account = self._create_account()

        info = self._get_identity_info(user_name, password)

        identity = Signon.Identity.new()
        identity.store_credentials_with_info(
            info, self._set_credentials_id_to_account, account)

        self._join_main_loop()
        return account

    def _create_account(self):
        account = self._manager.create_account('evernote')
        account.set_enabled(True)
        account.store(self._on_account_created, None)
        return account

    def _on_account_created(self, account, error, _):
        if error:
            self.error = error
            self._main_loop.quit()

    def _get_identity_info(self, user_name, password):
        info = Signon.IdentityInfo.new()
        info.set_username(user_name)
        info.set_caption(user_name)
        info.set_secret(password, True)
        return info

    def _set_credentials_id_to_account(self, identity, id, error, account):
        if error:
            self.error = error
            self._main_loop.quit()

        account.set_variant('CredentialsId', GLib.Variant('u', id))
        account.store(self._process_session, None)

    def _process_session(self, account, error, _):
        if error:
            self.error = error
            self._main_loop.quit()

        account_service = Accounts.AccountService.new(account, None)
        auth_data = account_service.get_auth_data()
        identity = auth_data.get_credentials_id()
        method = auth_data.get_method()
        mechanism = auth_data.get_mechanism()
        session_data = auth_data.get_parameters()
        note_store_url = 'https://sandbox.evernote.com/shard/s1/notestore'
        oauth_token = (
            'S=s1:U=8e6bf:E=14d08e375ff:C=145b1324a03:P=1cd:A=en-devtoken:'
            'V=2:H=79b946c32b4515ee52b387f7b68baa69')
        session_data['ProvidedTokens'] = GLib.Variant('a{sv}', {
            'TokenSecret': GLib.Variant('s', ''),
            'edam_userId': GLib.Variant('s', '583359'),
            'edam_noteStoreUrl': GLib.Variant('s', note_store_url),
            'oauth_token_secret': GLib.Variant('s', ''),
            'oauth_token': GLib.Variant('s', oauth_token),
            'edam_shard': GLib.Variant('s', 's1'),
            'AccessToken': GLib.Variant('s', oauth_token),
            'edam_webApiUrlPrefix': GLib.Variant(
                's', 'https://sandbox.evernote.com/shard/s1/'),
            'edam_expires': GLib.Variant('s', '1430347980')
        })
        session = Signon.AuthSession.new(identity, method)
        session.process(
            session_data, mechanism, self._on_login_processed, None)

    def _on_login_processed(self, session, reply, error, userdata):
        if error:
            self.error = error

        self._main_loop.quit()

    def delete_account(self, account):
        self._start_main_loop()
        account.delete()
        account.store(self._on_account_deleted, None)
        self._join_main_loop()

    def _on_account_deleted(self, account, error, userdata):
        if error:
            self.error = error

        self._main_loop.quit()
