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

import uuid

import testtools
from evernote.edam.error import ttypes as errors


from reminders import evernote


class EvernoteTestCase(testtools.TestCase):

    """Test the evernote access with the SDK."""

    def setUp(self):
        super(EvernoteTestCase, self).setUp()
        self.client = evernote.SandboxEvernoteClient()

    def create_test_notebook(self, name=None):
        if name is None:
            name = 'Test notebook {}'.format(uuid.uuid1())
        created_notebook = self.client.create_notebook(name)
        self.addCleanup(self.expunge_test_notebook, created_notebook.guid)
        return created_notebook

    def expunge_test_notebook(self, notebook_guid):
        try:
            self.client.expunge_notebook(notebook_guid)
        except errors.EDAMNotFoundException:
            # The notebook was already deleted or not successfully created.
            pass

    def create_test_note(self, title=None, content=None, notebook_guid=None):
        if title is None:
            title = 'Test note {}'.format(uuid.uuid1())
        if content is None:
            content = 'test content.'
        if notebook_guid is None:
            notebook = self.create_test_notebook()
            notebook_guid = notebook.guid

        created_note = self.client.create_note(title, content, notebook_guid)
        self.addCleanup(self.expunge_test_note, created_note.guid)
        return created_note

    def expunge_test_note(self, note_guid):
        try:
            self.client.expunge_note(note_guid)
        except errors.EDAMNotFoundException:
            # The note was already deleted or not successfully created.
            pass

    def test_create_notebook(self):
        """Test that we can create a notebook on the evernote server."""
        test_notebook_name = 'Test notebook {}'.format(uuid.uuid1())

        # An exception will be raised if the notebook can't be created.
        created_notebook = self.create_test_notebook(test_notebook_name)

        self.assertEqual(created_notebook.name, test_notebook_name)

    def test_create_note(self):
        """Test that we can create a note on the evernote server."""
        test_note_title = 'Test note {}'.format(uuid.uuid1())
        test_note_content = 'test content.'
        test_notebook = self.create_test_notebook()

        # An exception will be raised if the note can't be created.
        created_note = self.create_test_note(
            test_note_title, test_note_content, test_notebook.guid)

        self.assertEqual(created_note.title, test_note_title)
        created_note_content = self.client.get_note_content(
            created_note.guid)
        self.assertIn(test_note_content, created_note_content)

    def test_expunge_notebook_must_permanently_remove_it(self):
        """Test that an expunged notebook is no longer available."""
        created_notebook = self.create_test_notebook()

        self.client.expunge_notebook(created_notebook.guid)

        self.assertRaises(
            errors.EDAMNotFoundException,
            self.client.get_notebook,
            created_notebook.guid)

    def test_expunge_note_must_permanently_remove_it(self):
        """Test that an expunged note is no longer available."""
        created_note = self.create_test_note()

        self.client.expunge_note(created_note.guid)

        self.assertRaises(
            errors.EDAMNotFoundException,
            self.client.get_note,
            created_note.guid)

    def test_expunge_notebook_by_name_must_permanently_remove_it(self):
        """Test that an expunged notebook is no longer available."""
        created_notebook = self.create_test_notebook()

        self.client.expunge_notebook_by_name(created_notebook.name)

        self.assertRaises(
            errors.EDAMNotFoundException,
            self.client.get_notebook,
            created_notebook.guid)

    def test_get_unexisting_notebook_by_name_must_raise_exception(self):
        self.assertRaises(
            errors.EDAMNotFoundException,
            self.client.get_notebook_by_name,
            'I do not exist.')
