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
import Ubuntu.Components.ListItems 0.1
import Evernote 0.1
import "../components"

Page {
    id: notesPage

    property alias filter: notes.filterNotebookGuid

    onActiveChanged: {
        if (active) {
            NotesStore.refreshNotes();
        }
    }

    // Just for testing
    tools: ToolbarItems {
        ToolbarButton {
            text: "search"
            iconName: "search"
            onTriggered: {
                pagestack.push(Qt.resolvedUrl("SearchNotesPage.qml"))
            }
        }

        ToolbarSpacer { }

        ToolbarButton {
            text: "add note"
            enabled: notes.filterNotebookGuid.length > 0
            onTriggered: {
                var content = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\"><en-note><div><br clear=\"none\"/>"
                content = content + "fobar"
                content = content + "<br clear=\"none\"/></div><div><br clear=\"none\"/></div></en-note>"
                NotesStore.createNote("Untitled", notes.filterNotebookGuid, content);
            }
        }
    }

    Notes {
        id: notes
    }

    ListView {
        objectName: "notespageListview"
        anchors { left: parent.left; right: parent.right }
        height: parent.height - y
        model: notes

        delegate: Standard {
            text: title

            onClicked: {
                pageStack.push(Qt.resolvedUrl("NotePage.qml"), {note: NotesStore.note(guid)})
            }

            onPressAndHold: {
                NotesStore.deleteNote(guid);
            }
        }
    }
}
