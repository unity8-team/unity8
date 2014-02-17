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
import Ubuntu.Components.ListItems 0.1
import Ubuntu.Components.Popups 0.1
import Ubuntu.Components.Pickers 0.1

Empty {
    id: root
    height: expanded ? mainColumn.height : implicitHeight
    clip: true

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
        anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: units.gu(2); rightMargin: units.gu(2) }
        spacing: units.gu(2)
        height: implicitHeight + units.gu(1)

        Row {
            anchors { left: parent.left; right: parent.right }
            height: root.implicitHeight
            spacing: units.gu(1)

            CheckBox {
                id: checkBox
                anchors.verticalCenter: parent.verticalCenter
                checked: note.reminderDone
                onClicked: {
                    note.reminderDone = checked;
                    note.save();
                }
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: note.title
                width: parent.width - checkBox.width - reminderTimeRow.width - parent.spacing * 2
            }
            Row {
                id: reminderTimeRow
                anchors { top: parent.top; bottom: parent.bottom }
                spacing: units.gu(2)

                Label {
                    id: timeLabel
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDate(note.reminderTime)
                    visible: note.hasReminderTime
                    Component.onCompleted: print("Got reminder time", note.reminderTime)
                }
                Icon {
                    id: alarmIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: units.gu(4)
                    height: width
                    name: "alarm-clock"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.expanded = !root.expanded;
                    }
                }
            }
        }


        Row {
            id: datePicker
            width: childrenRect.width
            height: monthPicker.height
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(1)

            property var date: new Date()
            property int minYear: 2010
            property bool editing: false

            Picker {
                id: dayPicker
                model: getDays(monthPicker.selectedIndex, yearPicker.selectedIndex + 2010)
                function getDays(month, year) {
                    switch(month) {
                    case 1:
                        if (((year % 4 === 0) && (year % 100 !== 0)) || (year % 400 === 0)) {
                            return 29;
                        }
                        return 28;
                    case 3:
                    case 5:
                    case 8:
                    case 10:
                        return 30;
                    default:
                        return 31;
                    }
                }
                delegate: PickerDelegate {
                    Label {
                        anchors.centerIn: parent
                        text: modelData + 1
                    }
                }
                selectedIndex: datePicker.date.getDate() - 1
                onSelectedIndexChanged: {
                    datePicker.date.setDate(selectedIndex + 1)
                }
            }
            Picker {
                id: monthPicker
                model: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sept", "Oct", "Nov", "Dec"]
                delegate: PickerDelegate {
                    Label {
                        anchors.centerIn: parent
                        text: modelData
                    }
                }
                selectedIndex: datePicker.date.getMonth()
                onSelectedIndexChanged: {
                    var selectedDay = dayPicker.selectedIndex;
                    datePicker.date.setMonth(selectedIndex)
                    dayPicker.selectedIndex = selectedDay;
                }
            }
            Picker {
                id: yearPicker
                model: 100
                circular: false
                delegate: PickerDelegate {
                    Label {
                        anchors.centerIn: parent
                        text: datePicker.minYear + modelData
                    }
                }
                selectedIndex: datePicker.date.getFullYear() - datePicker.minYear
                onSelectedIndexChanged: {
                    var selectedDay = dayPicker.selectedIndex;
                    datePicker.date.setFullYear(selectedIndex + datePicker.minYear)
                    dayPicker.selectedIndex = selectedDay;
                }
            }
        }

        Row {
            spacing: units.gu(2)
            anchors { left: parent.left; right: parent.right }
            height: childrenRect.height

            Button {
                text: "Clear"
                width: (parent.width - parent.spacing) / 2
                onClicked: {
                    note.hasReminderTime = false;
                    root.expanded = false;
                }
            }
            Button {
                text: "OK"
                width: (parent.width - parent.spacing) / 2
                onClicked: {
                    print("setting date to ", datePicker.date)
                    note.reminderTime = datePicker.date
                    root.expanded = false;
                }
            }
        }
    }
}
