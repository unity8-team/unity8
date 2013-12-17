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
import Ubuntu.Components.Extras.Browser 0.1
import QtWebKit 3.1
import QtWebKit.experimental 1.0
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

    Flickable {
        anchors { fill: parent }
        contentHeight: height
        contentWidth: width

        UbuntuWebView {
            id: noteTextArea
            anchors { fill: parent}
            property string html: note.htmlContent
            onHtmlChanged: loadHtml(html, "file:///")

            experimental.preferences.navigatorQtObjectEnabled: true
            experimental.userScripts: [Qt.resolvedUrl("reminders-scripts.js")]
            experimental.onMessageReceived: {
                var data = null;
                try {
                    data = JSON.parse(message.data);
                } catch (error) {
                    print("Failed to parse message:", message.data, error);
                }

                switch (data.type) {
                case "checkboxChanged":
                    note.markTodo(data.todoId, data.checked);
                    NotesStore.saveNote(note.guid);
                    break;
                }
            }
        }
    }
}
