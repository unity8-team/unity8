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

    signal editNote(var note)

    onNoteChanged: {
        if (root.note != null) {
            NotesStore.refreshNoteContent(root.note.guid)
        }
    }

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
        anchors { fill: parent}

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
}
