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

ListItemWithActions {
    id: root
    height: units.gu(12)
    width: parent.width

    property string title
    property string date
    property string content
    property string resource
    property string tags
    property bool reminder
    property bool loading
    property bool synced
    property bool syncError
    property bool conflicting
    property string notebookColor

    signal deleteNote()
    signal editNote()
    signal editReminder()
    signal editTags()

    leftSideAction: Action {
        iconName: "delete"
        text: i18n.tr("Delete")
        onTriggered: {
            root.deleteNote()
        }
    }

    rightSideActions: [
        Action {
            iconName: "alarm-clock"
            text: i18n.tr("Reminder")
            onTriggered: {
                root.editReminder();
            }
        },
        Action {
            iconSource: "../images/tags.svg"
            text: i18n.tr("Tags")
            onTriggered: {
                root.editTags();
            }
        },
        Action {
            iconName: "edit"
            text: i18n.tr("Edit")
            onTriggered: {
                root.editNote();
            }
        }
    ]
    ColumnLayout {
        anchors { fill: parent }
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            height: units.gu(0.4)
            color: root.notebookColor
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: units.gu(1)
                        spacing: units.gu(1)

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Label {
                                id: titleLabel
                                Layout.fillWidth: true
                                text: root.title
                                font.weight: Font.Light
                                elide: Text.ElideRight
                                color: root.notebookColor
                            }
                            Label {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: "<font color=\"" + root.notebookColor + "\">" +
                                    Qt.formatDateTime(root.date, Qt.LocalDate) +
                                    " </font>" + root.content
                                wrapMode: Text.WordWrap
                                textFormat: Text.StyledText
                                maximumLineCount: 2
                                fontSize: "small"
                                color: "black"
                            }

                            Label {
                                Layout.fillWidth: true
                                text: root.tags
                                wrapMode: Text.WordWrap
                                maximumLineCount: 1
                                fontSize: "small"
                                color: "#b3b3b3"
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                            width: units.gu(2)

                            Icon {
                                anchors { left: parent.left; top: parent.top; right: parent.right }
                                height: width
                                name: root.reminder ? "alarm-clock" : ""
                                visible: root.reminder
                            }
                            Icon {
                                anchors { left: parent.left; verticalCenter: parent.verticalCenter; right: parent.right }
                                height: width
                                name: "go-next"
                            }
                            Icon {
                                anchors { left: parent.left; bottom: parent.bottom; right: parent.right }
                                height: width
                                name: root.loading ? "sync-updating" : root.syncError ? "sync-error" : root.synced ? "sync-idle" : root.conflicting ? "weather-severe-alert-symbolic" : "sync-offline"
                                visible: NotesStore.username !== "@local" && (!root.synced || root.syncError || root.loading || root.conflicting)
                            }
                        }
                    }
                }

                Image {
                    source: root.resource
                    sourceSize.height: units.gu(11.6)
                    asynchronous: true

                    Layout.maximumWidth: height
                    fillMode: Image.PreserveAspectCrop
                }
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop{ position: 0.8; color: "transparent" }
                    GradientStop{ position: 1; color: "#d9d9d9" }
                }
            }
        }

    }
}
