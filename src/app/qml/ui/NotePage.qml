/*
 * Copyright: 2013 Canonical, Ltd
 *
 * This file is part of reminders-app
 *
 * reminders-app is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
import Evernote 0.1
import "../components"

Page {
    id: root
    title: note.title
    property var note

    Component.onCompleted: NotesStore.refreshNoteContent(note.guid)

    tools: ToolbarItems {
        ToolbarButton {
            text: "delete"
            iconName: "delete"
            onTriggered: {
                NotesStore.deleteNote(note.guid);
                pagestack.pop();
            }
        }
        ToolbarSpacer {}
        ToolbarButton {
            text: note.reminder ? "reminder (set)" : "reminder"
            iconName: "alarm-clock"
            onTriggered: {
                note.reminder = !note.reminder
                NotesStore.saveNote(note.guid)
            }
        }
        ToolbarButton {
            text: "edit"
            iconName: "edit"
            onTriggered: {
                pagestack.pop()
                pagestack.push(Qt.resolvedUrl("EditNotePage.qml"), {note: root.note})
            }
        }
    }

    TextArea {
        id: noteTextArea
        anchors { fill: parent; margins: units.gu(2) }
        height: parent.height - y
        highlighted: true
        readOnly: true

        textFormat: TextEdit.RichText
        text: note.htmlContent
    }
}

