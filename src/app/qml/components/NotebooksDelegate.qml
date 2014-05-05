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
import QtQuick.Layouts 1.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1

Empty {
    id: root
    height: units.gu(9)

    property string name
    property string lastUpdatedString
    property int noteCount
    property string shareStatus
    property color notebookColor

    Rectangle {
        anchors.fill: parent
        color: "#f9f9f9"
        anchors.bottomMargin: units.dp(1)
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: units.gu(1)

        Item {
            anchors { top: parent.top; bottom: parent.bottom }
            width: units.gu(2)
            Rectangle {
                anchors { top: parent.top; bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; margins: units.gu(1.5) }
                width: units.gu(.5)
                color: root.notebookColor
                radius: width / 2
            }
        }

        ColumnLayout {
            height: parent.height
            Layout.fillWidth: true

            Label {
                text: root.name
                color: root.notebookColor
                fontSize: "medium"
                font.bold: true
            }
            Label {
                text: i18n.tr("Last edited %1").arg(root.lastUpdatedString)
                fontSize: "small"
                color: "black"
            }
            Label {
                Layout.fillHeight: true
                text: "foooo"
                color: "#b3b3b3"
                fontSize: "x-small"
                verticalAlignment: Text.AlignVCenter
            }
        }

        Label {
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
            text: "(" + root.noteCount + ")"
            color: "#b3b3b3"
        }
    }

//    Column {
//        id: contentColumn
//        anchors {
//            top: parent.top
//            topMargin: units.gu(1)
//            left: parent.left
//            leftMargin: units.gu(2)
//            right: resourceImage.left
//            rightMargin: units.gu(2)
//        }
//        Label {
//            anchors { left: parent.left; right: parent.right }
//            text: root.name
//            font.bold: true
//            elide: Text.ElideRight
//            color: root.notebookColor
//        }
//        Label {
//            anchors { left: parent.left; right: parent.right }
//            text: root.shareStatus
//            wrapMode: Text.WordWrap
//            textFormat: Text.StyledText
//        }
//    }

//    Label {
//        id: resourceImage
//        anchors { top: parent.top; right: parent.right; bottom: parent.bottom; topMargin: units.gu(1); rightMargin: units.gu(2) }
//        text: i18n.tr("%1 note", "%1 notes", root.noteCount).arg(root.noteCount)
//    }
}
