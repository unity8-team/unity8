/*
 * Copyright: 2015 Canonical, Ltd
 *
 * This file is part of reminders
 *
 * reminders is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.2
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1
import Evernote 0.1

ColumnLayout {
    id: root
    property var note: null

    signal clicked();
    signal deleteThis();
    signal keepThis();

    RowLayout {
        Layout.fillWidth: true
        Label {
            text: i18n.tr("Notebook:")
        }
        Label {
            Layout.fillWidth: true
            text: root.note ? NotesStore.notebook(root.note.notebookGuid).name : ""
        }
    }

    NotesDelegate {
        Layout.fillWidth: true

        title: root.note ? root.note.title : ""
        content: root.note ? root.note.plaintextContent : ""

        resource: root.note && root.note.resourceUrls.length > 0 ? root.note.resourceUrls[0] : ""
        notebookColor: root.note ? preferences.colorForNotebook(root.note.notebookGuid) : "black"
        reminder: root.note && root.note.reminder
        date: root.note ? root.note.updated : ""
        conflicting: true

        onItemClicked: root.clicked();
        onDeleteNote: root.deleteThis();
        onKeepThis: root.keepThis();
        deleted: root.note.deleted
    }
    RowLayout {
        visible: root.note && root.note.reminder
        Label {
            text: i18n.tr("Reminder:")
        }
        Label {
            text: root.note ? root.note.reminderTimeString : ""
            Layout.fillWidth: true
        }
        CheckBox {
            enabled: false
            checked: root.note ? root.note.reminderDone : false
        }
    }
}
