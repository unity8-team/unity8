/*
 * Copyright: 2015 Canonical, Ltd
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

import QtQuick 2.3
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0
import QtQuick.Layouts 1.1
import Evernote 0.1
import "../components"

Item {
    id: root

    property var note: null
    readonly property var conflictingNote: note.conflictingNote

    signal displayNote(var note);
    signal resolveConflict(bool keepLocal);

    Flickable {
        anchors.fill: parent
        contentHeight: column.height + units.gu(2)
        clip: true

        ColumnLayout {
            id: column
            anchors { left: parent.left; right: parent.right; top: parent.top}
            anchors.margins: units.gu(1)
            spacing: units.gu(2)

            RowLayout {
                spacing: units.gu(2)
                Icon {
                    height: units.gu(8)
                    width: height
                    name: "weather-severe-alert-symbolic"
                }
                Label {
                    text: i18n.tr("This note has been modified in multiple places. Please choose the version to be opened and delete the other.")
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }

            ThinDivider {}

            Label {
                text: root.note && root.note.deleted ? i18n.tr("Deleted on this device:") : i18n.tr("Modified on this device:")
                Layout.fillWidth: true
                font.bold: true
                wrapMode: Text.WordWrap
            }

            ConflictDelegate {
                Layout.fillWidth: true
                note: root.note

                onClicked: {
                    if (root.note) {
                        root.displayNote(note)
                    }
                }
                onDeleteThis: root.resolveConflict(false)
                onKeepThis: root.resolveConflict(true)
            }

            ThinDivider {}

            Label {
                text: root.note && root.conflictingNote && root.note.conflictingNote.deleted ? i18n.tr("Deleted from Evernote:") : i18n.tr("Modified somewhere else:")
                Layout.fillWidth: true
                font.bold: true
                wrapMode: Text.WordWrap
            }

            ConflictDelegate {
                Layout.fillWidth: true
                note: root.note ? root.note.conflictingNote : null
                onClicked: {
                    if (root.note && root.note.conflictingNote) {
                        root.displayNote(root.note.conflictingNote);
                    }
                }
                onDeleteThis: root.resolveConflict(true)
                onKeepThis: root.resolveConflict(false)
            }
        }
    }
}
