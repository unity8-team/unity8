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

import QtQuick 2.3
import QtQuick.Layouts 1.0
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0
import Ubuntu.Components.Popups 1.0
import Ubuntu.Components.Pickers 1.0
import Evernote 0.1

ListItemWithActions {
    id: root
    height: units.gu(10)
    clip: true
    color: "transparent"

    property var note

    leftSideAction: Action {
        text: i18n.tr("Clear reminder")
        iconName: "clear"
        onTriggered: {
            note.reminder = false;
            NotesStore.saveNote(note.guid)
        }
    }

    selectedRightActionColor: UbuntuColors.green
    triggerActionOnMouseRelease: true
    rightSideActions: [
        Action {
            iconSource: root.note.reminderDone ? "image://theme/select" : "../images/unchecked.svg"
            text: root.note.reminderDone ? i18n.tr("Mark as undone") : i18n.tr("Mark as done")
            onTriggered: {
                note.reminderDone = !root.note.reminderDone;
                NotesStore.saveNote(note.guid)
            }
        },
        Action {
            iconName: "alarm-clock"
            text: i18n.tr("Edit reminder")
            onTriggered: {
                pageStack.push(Qt.resolvedUrl("../ui/SetReminderPage.qml"), { note: root.note });
            }
        }
    ]

    Behavior on height {
        UbuntuNumberAnimation {}
    }

    RowLayout {
        anchors { fill: parent; margins: units.gu(1) }
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
                    horizontalAlignment: Text.AlignHCenter
                    font.bold: true
                    fontSize: "large"
                }
                Label {
                    text: note.hasReminderTime ? Qt.formatDateTime(note.reminderTime, "mm") : "00"
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    fontSize: "large"
                }
            }
        }

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: units.gu(1)

            Label {
                id: titleLabel
                text: note.title
                Layout.fillWidth: true
                fontSize: "large"
                horizontalAlignment: Text.AlignLeft
                color: "black"
                elide: Text.ElideRight
            }

            Label {
                text: note.tagline
                fontSize: "small"
                horizontalAlignment: Text.AlignLeft
                Layout.fillWidth: true
                maximumLineCount: 2
                width: parent.width
                wrapMode: Text.WordWrap
                color: "black"
            }
        }

        Item {
            Layout.fillHeight: true
            width: units.gu(2)

            Icon {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; right: parent.right }
                height: width
                name: "go-next"
            }
            Icon {
                anchors { left: parent.left; bottom: parent.bottom; right: parent.right }
                height: width
                name: model.loading ? "sync-updating" : model.syncError ? "sync-error" : model.synced ? "sync-idle" : "sync-offline"
                visible: NotesStore.username !== "@local" && (!model.synced || model.syncError || model.loading)
            }
        }
    }
}
