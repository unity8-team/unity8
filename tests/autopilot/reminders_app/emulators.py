# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright (C) 2013 Canonical Ltd.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

import logging

from autopilot import logging as autopilot_logging
from ubuntuuitoolkit import emulators as toolkit_emulators
from time import sleep

logger = logging.getLogger(__name__)

class MainView(toolkit_emulators.MainView):

    retry_delay = 0.2

    def select_many_retry(self, object_type, **kwargs):
        """Returns the item that is searched for with app.select_many
        In case of no item was not found (not created yet) a second attempt is
        taken 1 second later"""
        items = self.select_many(object_type, **kwargs)
        tries = 10
        while len(items) < 1 and tries > 0:
            sleep(self.retry_delay)
            items = self.select_many(object_type, **kwargs)
            tries = tries - 1
        return items

    #@autopilot_logging.log_action(logger.info)
    #def get_evernote_account(self):
         #"""Get Evernote account """
        #return self.wait_select_single(
        #"Standard", objectName="EvernoteAccount")

    #@autopilot_logging.log_action(logger.info)
    #def get_accountselectorpage(self):
        #"""Get Account selector page  """
        #return self.wait_select_single(
            #"Page", objectName="Accountselectorpage")

    @autopilot_logging.log_action(logger.info)
    def get_notespageListview(self):
        """Get notes page list view """
        return self.wait_select_single(
            "QQuickListView", objectName="notespageListview")
