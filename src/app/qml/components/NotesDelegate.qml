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
    height: units.gu(12)

    property string title
    property date creationDate
    property string content
    property string resource
    property string notebookColor: preferences.colorForNotebook(model.guid)

    showDivider: false;

    ColumnLayout {
        anchors { fill: parent; leftMargin: units.gu(1); rightMargin: units.gu(1) }
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

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    gradient: Gradient {
                        GradientStop{ position: 0.8; color: "transparent" }
                        GradientStop{ position: 1; color: "#d9d9d9" }
                    }

                    Base {
                        anchors.fill: parent
                        progression: true
                        showDivider: false

                        onClicked: root.clicked()   // Propagate the signal

                        ColumnLayout {
                            anchors { fill: parent; topMargin: units.gu(1); bottomMargin: units.gu(1) }

                            Label {
                                Layout.fillWidth: true
                                text: root.title
                                font.weight: Font.Light
                                elide: Text.ElideRight
                                color: root.notebookColor
                            } 

                            Label {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: root.content
                                wrapMode: Text.WordWrap
                                textFormat: Text.StyledText
                                maximumLineCount: 2
                                fontSize: "small"
                                color: "black"
                            }

                            Label {
                                Layout.minimumWidth: parent.width + units.gu(2)
                                text: Qt.formatDateTime(root.creationDate, "dddd, hh:mm")
                                color: "#b3b3b3"
                                fontSize: "small"
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }

                Image {
                    source: root.resource
                    sourceSize.height: units.gu(11.6)

                    Layout.maximumWidth: parent.width / 2

                    Rectangle {
                        height: parent.width 
                        width: parent.height

                        anchors.centerIn: parent
                        rotation: 90
                        
                        gradient: Gradient {
                            GradientStop{ position: 0; color: "#383838" }
                            GradientStop{ position: 0.1; color: "transparent" }
                            GradientStop{ position: 0.9; color: "transparent" }
                            GradientStop{ position: 1; color: "#383838" }
                        }
                    }
                }
            }
        }
    }
}
