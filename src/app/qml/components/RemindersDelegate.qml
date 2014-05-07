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
import QtQuick.Layouts 1.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Components.Pickers 0.1

Base {
    id: root
    height: expanded ? mainColumn.height : units.gu(10)
    clip: true
    progression: true

    property var note

    property bool expanded: false

    onExpandedChanged: {
        if (expanded) {
            if (note.hasReminderTime) {
                datePicker.date.setDate(note.reminderTime.getDate())
            }
        } else {
            note.save();
        }
    }

    Behavior on height {
        UbuntuNumberAnimation {}
    }

    Column {
        id: mainColumn
        anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: units.gu(2); rightMargin: units.gu(2); topMargin: units.gu(1) }
        spacing: units.gu(2)
        height: implicitHeight + units.gu(1)

        RowLayout {
            anchors { left: parent.left; right: parent.right }
            height: units.gu(8)
            spacing: units.gu(1)

            UbuntuShape {
                Layout.fillHeight: true
                width: height
                color: preferences.colorForNotebook(note.notebookGuid)
                radius: "medium"

                Column {
                    anchors.centerIn: parent
                    Label {
                        text: note.hasReminderTime ? Qt.formatDateTime(note.reminderTime, "hh") : "00"
                        color: "white"
                        horizontalAlignment: parent.horizontalCenter
                        font.bold: true
                        fontSize: "large"
                    }
                    Label {
                        text: note.hasReminderTime ? Qt.formatDateTime(note.reminderTime, "mm") : "00"
                        color: "white"
                        horizontalAlignment: parent.horizontalCenter
                        fontSize: "large"
                    }
                }
            }

            Column {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: units.gu(1)

                Label {
                    text: note.title
                    fontSize: "large"
                    horizontalAlignment: Text.AlignLeft
                    color: "black"
                }
                Label {
                    text: note.plaintextContent
                    fontSize: "small"
                    horizontalAlignment: Text.AlignLeft
                    maximumLineCount: 2
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: "black"
                }
            }
        }
    }
}
