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
            text: note.reminder ? i18n.tr("Edit reminder") : i18n.tr("Set reminder")
            // TODO: use this instead when the toolkit switches from using the
	    // ubuntu-mobile-icons theme to suru:
            //iconName: note.reminder ? "reminder" : "reminder-new"
            iconSource: note.reminder ?
                Qt.resolvedUrl("/usr/share/icons/suru/actions/scalable/reminder.svg") :
                Qt.resolvedUrl("/usr/share/icons/suru/actions/scalable/reminder-new.svg")
            onTriggered: {
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
