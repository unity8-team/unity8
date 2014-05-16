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
import Ubuntu.Components.Pickers 0.1
import Evernote 0.1
import "../components"

Item {
    id: root
    property string title: note.title
    property var note

    ColumnLayout {
        anchors { top: parent.top; topMargin: units.gu(2); horizontalCenter: parent.horizontalCenter }
        spacing: units.gu(2)

        Label {
            text: i18n.tr("Select date and time for the reminder:")
            Layout.fillWidth: true
        }

        DatePicker {
            id: datePicker
            date: note.hasReminderTime ? note.reminderTime : new Date()
        }

        DatePicker {
            id: timePicker
            mode: "Hours|Minutes"
            date: note.hasReminderTime ? note.reminderTime : new Date()
        }

        RowLayout {
            Layout.fillWidth: true

            Button {
                text: i18n.tr("Clear reminder")
                Layout.fillWidth: true
                onClicked: {
                    note.reminder = false;
                    NotesStore.saveNote(note.guid);
                    pageStack.pop();
                }
            }

            Button {
                Layout.fillWidth: true
                text: i18n.tr("Set reminder")
                onClicked: {
                    note.reminder = true;
                    var date = datePicker.date
                    var time = timePicker.date
                    date.setHours(time.getHours());
                    date.setMinutes(time.getMinutes());
                    note.reminderTime = date;
                    print("set reminder time to", Qt.formatDate(date))
                    NotesStore.saveNote(note.guid)
                    pageStack.pop();
                }
            }

        }
    }
}
