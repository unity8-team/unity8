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

    property string notebookColor: preferences.colorForNotebook(model.guid)

    Rectangle {
        anchors.fill: parent
        color: "#f9f9f9"
        anchors.bottomMargin: units.dp(1)
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: units.gu(1)
        spacing: units.gu(1)

        Item {
            Layout.fillHeight: true
            width: units.gu(1)
            Rectangle {
                anchors { top: parent.top; bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; margins: units.gu(1.5) }
                width: units.gu(.5)
                color: root.notebookColor
                radius: width / 2
            }
        }

        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true

            Label {
                id: notebookTitleLabel
                objectName: 'notebookTitleLabel'
                text: model.name
                color: root.notebookColor
                fontSize: "large"
                Layout.fillWidth: true

                MouseArea {
                    onPressAndHold: {
                        notebookTitleLabel.visible = false;
                        notebookTitleTextField.forceActiveFocus();
                    }
                    anchors.fill: parent
                    propagateComposedEvents: true
                }
            }

            TextField {
                id: notebookTitleTextField
                text: model.name
                color: root.notebookColor
                visible: !notebookTitleLabel.visible
                Layout.fillWidth: true

                InverseMouseArea {
                    onClicked: {
                        if (notebookTitleTextField.text) {
                            notebooks.notebook(index).name = notebookTitleTextField.text;
                            NotesStore.saveNotebook(notebooks.notebook(index).guid);
                            notebookTitleLabel.visible = true;
                        }
                    }
                    anchors.fill: parent
                }
            }

            Label {
                objectName: 'notebookLastUpdatedLabel'
                text: i18n.tr("Last edited %1").arg(model.lastUpdatedString)
                fontSize: "small"
                color: "black"
                Layout.fillWidth: true
            }

            Label {
                objectName: 'notebookPublishedLabel'
                Layout.fillHeight: true
                text: model.published ? i18n.tr("Shared") : i18n.tr("Private")
                color: model.published ? "black" : "#b3b3b3"
                fontSize: "x-small"
                verticalAlignment: Text.AlignVCenter
                font.bold: model.published
            }
        }

        Item {
            Layout.fillHeight: true
            width: units.gu(2)

             Label {
                anchors { left: parent.left; top: parent.top; right: parent.right }
                height: width
                color: "#b3b3b3"
                text: "(" + model.noteCount + ")"
                fontSize: "small"
                horizontalAlignment: Text.AlignRight
            }
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
