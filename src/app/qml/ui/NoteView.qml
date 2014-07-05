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
import Ubuntu.Components.Extras.Browser 0.2
import Evernote 0.1
import "../components"

Item {
    id: root
    property string title: note.title
    property var note

    signal editNote(var note)

    onNoteChanged: {
        print("refreshing note:", root.note.guid)
        NotesStore.refreshNoteContent(root.note.guid)
    }

    ActivityIndicator {
        anchors.centerIn: parent
        running: root.note.loading
        visible: running
    }

    // FIXME: This is a workaround for an issue in the WebView. For some reason certain
    // documents cause a binding loop in the webview's contentHeight. Wrapping it inside
    // another flickable prevents this from happening.
    Flickable {
        anchors { fill: parent }
        contentHeight: height

        UbuntuWebView {
            id: noteTextArea
            anchors { fill: parent}
            property string html: note.htmlContent
            onHtmlChanged: {
                loadHtml(html, "file:///")
            }

            Connections {
                target: note
                onResourcesChanged: {
                    noteTextArea.loadHtml(noteTextArea.html, "file:///")
                }
            }


            Component.onCompleted: debug(noteTextArea, 0)
            function debug(id, level) {
                var level_string = '';

                for (var i = 0; i < level; i++) {
                    if (i+1 === level) {
                        level_string += '|--------';
                    }
                    else {
                        level_string += '         ';
                    }
                }

                if (level === 0) { 
                    level_string = 'property ';
                }
                else {
                    level_string += '> ';
                }

                for (var value in id) {

                    if (value != 'parent' && value != 'anchors' && value != 'data' && value != 'resources' && value != 'children') {
                        if (typeof(id[value]) === 'function') {
                            if (level === 0) {
                                console.log('function ' + value + '()');
                            }
                            else {
                                console.log(level_string + 'function ' + value + '()');
                            }
                        }
                        else if (typeof(id[value]) === 'object') {
                            console.log(level_string + value + ' [object]');
                            debug(id[value], level+1);
                        }
                        else {
                            console.log(level_string + value + ': ' + id[value] + ' [' + typeof(id[value]) + ']');
                        }
                    }
                }
            }
            /*preferences.standardFontFamily: 'Ubuntu'
            //preferences.navigatorQtObjectEnabled: true
            //preferredMinimumContentsWidth: root.width
            context.userScripts: [Qt.resolvedUrl("reminders-scripts.js")]
            onMessageReceived: {
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
            }*/
        }
    }
}
