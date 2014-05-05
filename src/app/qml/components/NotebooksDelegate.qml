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
import Ubuntu.Components.ListItems 0.1

Empty {
    id: root
    height: units.gu(6)

    property string name
    property int noteCount
    property string shareStatus
    property color notebookColor

    Column {
        id: contentColumn
        anchors {
            top: parent.top
            topMargin: units.gu(1)
            left: parent.left
            leftMargin: units.gu(2)
            right: resourceImage.left
            rightMargin: units.gu(2)
        }
        Label {
            anchors { left: parent.left; right: parent.right }
            text: root.name
            font.bold: true
            elide: Text.ElideRight
            color: root.notebookColor
        }
        Label {
            anchors { left: parent.left; right: parent.right }
            text: root.shareStatus
            wrapMode: Text.WordWrap
            textFormat: Text.StyledText
        }
    }

    Label {
        id: resourceImage
        anchors { top: parent.top; right: parent.right; bottom: parent.bottom; topMargin: units.gu(1); rightMargin: units.gu(2) }
        text: i18n.tr("%1 note", "%1 notes", root.noteCount).arg(root.noteCount)
    }
}
