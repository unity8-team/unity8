/*
 * Copyright: 2013 Canonical, Ltd
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

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.Extras.Browser 0.1
import QtWebKit 3.1
import QtWebKit.experimental 1.0
import Evernote 0.1
import "../components"

Page {
    id: root
    title: noteView.title
    property alias note: noteView.note

    signal editNote(var note)

    tools: ToolbarItems {
        ToolbarButton {
            text: i18n.tr("Delete")
            iconName: "delete"
            onTriggered: {
                NotesStore.deleteNote(note.guid);
                pagestack.pop();
            }
        }
        ToolbarSpacer {}
        ToolbarButton {
            text: note.reminder ? "Reminder (set)" : "Reminder"
            iconName: "alarm-clock"
            onTriggered: {
                print("opening reminder dialog")
                pageStack.push(Qt.resolvedUrl("SetReminderPage.qml"), {title: root.title, note: root.note});
            }
        }
        ToolbarButton {
            text: i18n.tr("Edit")
            iconName: "edit"
            onTriggered: {
                root.editNote(root.note)
            }
        }
    }

    NoteView {
        id: noteView
        anchors.fill: parent

        onEditNote: {
            root.editNote(note) ;
        }
    }
}
