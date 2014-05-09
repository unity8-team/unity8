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
import Evernote 0.1
import "../components"

Item {
    id: root
    property string title: note.title
    property var note

    signal editNote(var note)

    QtObject {
        id: priv
        property bool loading: false
    }

    Component.onCompleted: {
        if (note.enmlContent.length === 0) {
            NotesStore.refreshNoteContent(root.note.guid)
            priv.loading = true;
        }
    }

    Connections {
        target: NotesStore
        onNoteChanged: {
            if (guid === root.note.guid) {
                priv.loading = false;
            }
        }
    }

    ActivityIndicator {
        anchors.centerIn: parent
        running: priv.loading
        visible: running
    }

    // FIXME: This is a workaround for an issue in the WebView. For some reason certain
    // documents cause a binding loop in the webview's contentHeight. Wrapping it inside
    // another flickable prevents this from happening.
    Flickable {
        anchors { fill: parent }
        contentHeight: height
        visible: !priv.loading

        UbuntuWebView {
            id: noteTextArea
            anchors { fill: parent}
            property string html: note.htmlContent
            onHtmlChanged: {
                loadHtml(html, "file:///")
            }

            experimental.preferences.standardFontFamily: 'Ubuntu'
            experimental.preferences.navigatorQtObjectEnabled: true
            experimental.preferredMinimumContentsWidth: root.width
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
