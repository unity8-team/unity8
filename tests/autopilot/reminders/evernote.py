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


from evernote.api import client
from evernote.edam.type import ttypes
from evernote.edam.error import ttypes as errors


TEST_OAUTH_TOKEN = (
    'S=s1:U=8e6bf:E=14d08e375ff:C=145b1324a03:P=1cd:A=en-devtoken:V=2:'
    'H=79b946c32b4515ee52b387f7b68baa69')
EVERNOTE_NOTE_XML_PROLOG = (
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml2.dtd">')
EVERNOTE_NOTE_XML_ELEMENT_FORMAT = '<en-note>{}</en-note>'


class SandboxEvernoteClient(client.EvernoteClient):

    """Client to access the Evernote API on the sandbox server."""

    def __init__(self):
        super(SandboxEvernoteClient, self).__init__(
            token=TEST_OAUTH_TOKEN, sandbox=True)

    @property
    def note_store(self):
        return self.get_note_store()

    def create_notebook(self, name):
        """Create a notebook.

        :param name: The name of the notebook to create.
        :return: The created notebook.

        """
        notebook = ttypes.Notebook()
        notebook.name = name

        return self.note_store.createNotebook(notebook)

    def create_note(self, title, content, notebook_guid):
        """Create a note.

        :param title: The title of the note to create.
        :param content: The content to add to the note.
        :return: The created note.

        """
        note = ttypes.Note()
        note.title = title
        note.content = EVERNOTE_NOTE_XML_PROLOG
        note.content += EVERNOTE_NOTE_XML_ELEMENT_FORMAT.format(content)
        note.notebookGuid = notebook_guid

        return self.note_store.createNote(note)

    def get_note_content(self, note_guid):
        """Return the content of a note.

        :param note_guid: The GUID of the note.
        :return: The content of the note.

        """
        return self.note_store.getNoteContent(note_guid)

    def expunge_notebook(self, notebook_guid):
        """Permanently remove a notebook.

        :param notebook_guid: The GUID of the notebook to expunge.

        """
        self.note_store.expungeNotebook(notebook_guid)

    def get_notebook(self, notebook_guid):
        """Return a notebook.

        :param notebook_guid: The GUID of the notebook.

        """
        return self.note_store.getNotebook(notebook_guid)

    def expunge_note(self, note_guid):
        """Permanently remove a note.

        :param note_guid: The GUID of the note to expunge.

        """
        return self.note_store.expungeNote(note_guid)

    def get_note(self, note_guid):
        """Return a note.

        :param note_guid: The GUID of the note.

        """
        return self.note_store.getNote(note_guid, False, False, False, False)

    def expunge_notebook_by_name(self, name):
        """Permanently remove a notebook.

        :param name: The first notebook found with this name will be expunged.

        """
        notebook = self.get_notebook_by_name(name)
        self.expunge_notebook(notebook.guid)

    def get_notebook_by_name(self, name):
        """Return a notebook.

        :param name: The first notebook found with this name will be returned.

        """
        notebooks = self.note_store.listNotebooks()
        for notebook in notebooks:
            if notebook.name == name:
                return notebook
        else:
            raise errors.EDAMNotFoundException()
