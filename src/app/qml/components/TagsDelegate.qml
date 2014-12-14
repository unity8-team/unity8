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

import QtQuick 2.3
import QtQuick.Layouts 1.0
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0
import Evernote 0.1

Empty {
    id: root
    height: units.gu(10)

    Rectangle {
        anchors.fill: parent
        color: "#f9f9f9"
        anchors.bottomMargin: units.dp(1)
    }

    Base {
        anchors.fill: parent
        progression: true

        onClicked: root.clicked()

        Icon {
            height: units.gu(2.5)
            width: height
            anchors { top: parent.top; right: parent.right; topMargin: units.gu(1) }
            name: model.loading ? "sync-updating" : model.syncError ? "sync-error" : model.synced ? "sync-idle" : "sync-offline"
            visible: NotesStore.username !== "@local"
        }

        RowLayout {
            anchors { fill: parent; topMargin: units.gu(1); bottomMargin: units.gu(1) }
            spacing: units.gu(1)

            Item {
                anchors { top: parent.top; bottom: parent.bottom }
                width: units.gu(1)
                Rectangle {
                    anchors { top: parent.top; bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; margins: units.gu(1.5) }
                    width: units.gu(.5)
                    color: "black"
                    radius: width / 2
                }
            }

            ColumnLayout {
                height: parent.height
                Layout.fillWidth: true

                Label {
                    id: tagTitleLabel
                    objectName: 'tagTitleLabel'
                    text: model.name
                    fontSize: "large"
                    Layout.fillWidth: true

                    MouseArea {
                        onPressAndHold: {
                            tagTitleLabel.visible = false;
                            tagTitleTextField.forceActiveFocus();
                        }
                        anchors.fill: parent
                        propagateComposedEvents: true
                    }
                }

                TextField {
                    id: tagTitleTextField
                    text: model.name
                    visible: !tagTitleLabel.visible

                    InverseMouseArea {
                        onClicked: {
                            if (tagTitleTextField.text) {
                                tags.tag(index).name = tagTitleTextField.text;
                                NotesStore.saveTag(tags.tag(index).guid);
                                tagTitleLabel.visible = true;
                            }
                        }
                        anchors.fill: parent
                    }
                }
            }

            Label {
                objectName: 'tagNoteCountLabel'
                Layout.fillHeight: true
                verticalAlignment: Text.AlignVCenter
                text: "(" + model.noteCount + ")"
                color: "#b3b3b3"
            }
        }
    }
}
