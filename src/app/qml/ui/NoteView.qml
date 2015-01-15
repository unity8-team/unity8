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

import QtQuick 2.3
import Ubuntu.Components 1.1
import com.canonical.Oxide 1.0
import Evernote 0.1
import "../components"

Item {
    id: root
    property string title: note ? note.title : ""
    property var note: null

    signal openTaggedNotes(string title, string tagGuid)

    BouncingProgressBar {
        anchors.top: parent.top
        visible: root.note == null || root.note.loading
        z: 10
    }

    WebContext {
        id: webContext

        userScripts: [
            UserScript {
                context: 'reminders://todo'
                url: Qt.resolvedUrl("reminders-scripts.js");
            }
        ]
    }

    WebView {
        id: noteTextArea
        width: parent.width
        height: parent.height - tagsRow.height - (tagsRow.height > 0 ? units.gu(2) : 0)

        property string html: root.note ? note.htmlContent : ""

        onHtmlChanged: {
            loadHtml(html, "file:///")
        }

        context: webContext
        preferences.standardFontFamily: 'Ubuntu'
        preferences.minimumFontSize: 14

        Connections {
            target: note ? note : null
            onResourcesChanged: {
                noteTextArea.loadHtml(noteTextArea.html, "file:///")
            }
        }

        messageHandlers: [
            ScriptMessageHandler {
                msgId: 'todo'
                contexts: ['reminders://todo']
                callback: function(message, frame) {
                    var data = message.args;

                    switch (data.type) {
                        case "checkboxChanged":
                        note.markTodo(data.todoId, data.checked);
                        NotesStore.saveNote(note.guid);
                        break;
                    }
                }
            }
        ]
    }

    ListView {
        id: tagsRow
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: units.gu(1) }
        model: root.note ? root.note.tagGuids.length : undefined
        orientation: ListView.Horizontal
        spacing: units.gu(1)
        height: units.gu(3)

        delegate: Rectangle {
            id: rectangle
            radius: units.gu(1)
            color: "white"
            border.color: preferences.colorForNotebook(root.note.notebookGuid)

            Text {
                text: NotesStore.tag(root.note.tagGuids[index]).name
                color: preferences.colorForNotebook(root.note.notebookGuid)
                Component.onCompleted: {
                    rectangle.width = width + units.gu(2)
                    rectangle.height = height + units.gu(1)
                    anchors.centerIn = parent
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!narrowMode) {
                        sideViewLoader.clear();
                    }
                    root.openTaggedNotes(NotesStore.tag(root.note.tagGuids[index]).name, NotesStore.tag(root.note.tagGuids[index]).guid)
                }
            }
        }
    }
}
