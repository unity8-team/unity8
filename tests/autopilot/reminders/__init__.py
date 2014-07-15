# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright (C) 2013, 2014 Canonical Ltd.
#
# This file is part of reminders
#
# reminders is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 3.
#
# reminders is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

"""Reminders app tests and emulators - top level package."""

import logging
from distutils import version

import ubuntuuitoolkit

import autopilot
from autopilot import logging as autopilot_logging
from autopilot.introspection import dbus

logger = logging.getLogger(__name__)


class RemindersAppException(Exception):

    """Exception raised when there's an error in the Reminders App."""


class RemindersApp(object):

    """Autopilot helper object for the Reminders application."""

    def __init__(self, app_proxy):
        self.app = app_proxy
        self.main_view = self.app.select_single(MainView)

    def open_notebooks(self):
        """Open the Notebooks page.

        :return: The autopilot custom proxy object for the NotebooksPage.

        """
        self.main_view.switch_to_tab('NotebookTab')
        return self.main_view.select_single(
            NotebooksPage, objectName='notebooksPage')


class MainView(ubuntuuitoolkit.MainView):

    """Autopilot custom proxy object for the MainView."""

    def __init__(self, *args):
        super(MainView, self).__init__(*args)
        self.visible.wait_for(True)
        try:
            self._no_account_dialog = self.select_single(
                objectName='noAccountDialog')
        except dbus.StateNotFoundError:
            self._no_account_dialog = None

    @property
    def no_account_dialog(self):
        if self._no_account_dialog is None:
            raise RemindersAppException(
                'The No Account dialog is not present')
        else:
            return self._no_account_dialog


class NoAccountDialog(ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase):

    """Autopilot custom proxy object for the no account dialog."""

    @classmethod
    def validate_dbus_object(cls, path, state):
        if (version.LooseVersion(autopilot.version) >=
                version.LooseVersion('1.5')):
            # TODO there's an autopilot branch that will put the function in a
            # public module. Update this once the branch is released.
            # --elopio - 2014-05-16
            from autopilot.introspection import _xpathselect
            name = _xpathselect.get_classname_from_path(path)
        else:
            name = dbus.get_classname_from_path(path)
        if name == 'Dialog':
            if 'noAccountDialog' == state['objectName'][1]:
                return True
        return False

    @autopilot_logging.log_action(logger.info)
    def open_account_settings(self):
        button = self.select_single('Button', objectName='openAccountButton')
        self.pointing_device.click_object(button)


class _Page(ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase):

    def __init__(self, *args):
        super(_Page, self).__init__(*args)
        # XXX we need a better way to keep reference to the main view.
        # --elopio - 2014-02-26
        self.main_view = self.get_root_instance().select_single(MainView)


class PulldownListView(ubuntuuitoolkit.QQuickListView):

    """Autopilot custom proxy object for the PulldownListView."""


class NotebooksPage(_Page):

    """Autopilot custom proxy object for the Notebooks page."""

    def add_notebook(self, title):
        """Add a notebook.

        :param title: The title of the Notebook that will be added.

        """
        original_number_of_books = self._get_notebooks_listview().count
        header = self.main_view.get_header()
        header.click_action_button('addNotebookButton')
        title_textfield = self.select_single(
            ubuntuuitoolkit.TextField, objectName='newNoteTitleTextField')
        title_textfield.write(title)
        self._click_save()
        self._get_notebooks_listview().count.wait_for(
            original_number_of_books + 1)

    def _get_notebooks_listview(self):
        return self.select_single(
            PulldownListView, objectName='notebooksListView')

    def _click_save(self):
        save_button = self.select_single('Button', objectName='saveButton')
        self.pointing_device.click_object(save_button)

    def get_notebooks(self):
        """Return the list of Notebooks.

        :return: A list with the the Notebooks. Every item of the list is a
            tuple with title, last updated value, published status and number
            of notes. The list is sorted in the same order as it is displayed
            on the application.

        """
        listview = self._get_notebooks_listview()
        notebook_delegates = listview.select_many(NotebooksDelegate)
        # Sort by the position on the list.
        sorted_notebook_delegates = sorted(
            notebook_delegates,
            key=lambda delegate: delegate.globalRect.y)
        notebooks = [
            (notebook.get_title(), notebook.get_last_updated(),
             notebook.get_published_status(), notebook.get_notes_count())
            for notebook in sorted_notebook_delegates
        ]
        return notebooks


class NotebooksDelegate(ubuntuuitoolkit.UbuntuUIToolkitCustomProxyObjectBase):

    """Autopilot custom proxy object for the NotebooksDelegate."""

    def get_title(self):
        """Return the title of the Notebook."""
        return self._get_label_text('notebookTitleLabel')

    def _get_label_text(self, object_name):
        label = self.select_single('Label', objectName=object_name)
        return label.text

    def get_last_updated(self):
        """Return the last updated value of the Notebook."""
        return self._get_label_text('notebookLastUpdatedLabel')

    def get_published_status(self):
        """Return the published status of the Notebook."""
        return self._get_label_text('notebookPublishedLabel')

    def get_notes_count(self):
        """Return the number of notes in the Notebook."""
        # The count is returned in paretheses, so we strip them.
        return int(self._get_label_text('notebookNoteCountLabel').strip('()'))
