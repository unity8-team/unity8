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

Page {
    title: note.title
    property var note

    Column {
        anchors.fill: parent
        spacing: units.gu(1)
        Button {
            width: parent.width
            text: "save"
            onClicked: {
                note.content = noteTextArea.text
                note.save();
            }
        }

        TextArea {
            id: noteTextArea
            anchors { left: parent.left; right: parent.right }
            height: parent.height - y

            textFormat: TextEdit.RichText
            text: note.content
        }
    }
}

