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
// FIXME: we need com.canonical.Oxide to have UserScript type available and
// WebContextDelegateWorker to intercette messages. As
// soon as this will be implemented also in Ubuntu.Web we will switch to last
// one
import com.canonical.Oxide 1.0 
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

    WebContext {
        id: webContext 

        userScripts: [
            UserScript {
                url: Qt.resolvedUrl("reminders-scripts.js");
            }
        ]

        networkRequestDelegate: WebContextDelegateWorker {
            source: Qt.resolvedUrl("message-api.js");
            onMessage: console.log('onMessage')
        }
    }

    WebView {
        id: noteTextArea
        anchors { fill: parent}
        property string html: note.htmlContent
        onHtmlChanged: {
            console.log('@@@@@@@@@@@@@@@@@@@@@@@@@')
            console.log(html)
            loadHtml(html, "file:///")
        }

        Connections {
            target: note
            onResourcesChanged: {
                noteTextArea.loadHtml(noteTextArea.html, "file:///")
            }
        }

        context: webContext;
        preferences.standardFontFamily: 'Ubuntu'
     }
}
