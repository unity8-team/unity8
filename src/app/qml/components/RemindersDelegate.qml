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

Base {
    id: root
    height: units.gu(10)
    clip: true
    progression: true
    removable: true

    backgroundIndicator: Row {
        x: root.__contents.x > 0 ? root.__contents.x - width : 0
        width: childrenRect.width
        anchors.verticalCenter: parent.verticalCenter
        spacing: units.gu(1)

        Icon {
            height: units.gu(3)
            width: height
            anchors.verticalCenter: parent.verticalCenter
            name: root.note.reminderDone ? "clear" : "select"
        }

        Label {
            id: confirmRemovalDialog
            anchors.verticalCenter: parent.verticalCenter
            text: root.note.reminderDone ? i18n.tr("Clear reminder") : i18n.tr("Mark as done")
        }
    }

    property var note

    Behavior on height {
        UbuntuNumberAnimation {}
    }

    onItemRemoved: {
        // Revert "removal"
        root.cancelItemRemoval();
        root.height = units.gu(10)
        print("marking reminder as", !note.reminderDone, " done for note", note.title);
        if (!note.reminderDone) {
            note.reminderDone = true;
        } else {
            note.reminder = false;
        }

        NotesStore.saveNote(note.guid)
    }

    Column {
        id: mainColumn
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: units.gu(1) }
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
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: units.gu(1)

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        id: titleLabel
                        text: note.title
                        Layout.fillWidth: true
                        fontSize: "large"
                        horizontalAlignment: Text.AlignLeft
                        color: "black"
                        elide: Text.ElideRight
                    }
                    Icon {
                        height: titleLabel.height
                        width: height
                        name: model.loading ? "sync-updating" : model.syncError ? "sync-error" : model.synced ? "sync-idle" : "sync-offline"
                        visible: NotesStore.username !== "@local"
                    }
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
        }
    }
}
