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

    RowLayout {
        id: contentRow

        anchors { fill: parent; leftMargin: units.gu(1.5); rightMargin: units.gu(1.5) }

        ColumnLayout {
            Layout.fillHeight: true  
            Layout.maximumHeight: units.gu(12)

            Rectangle {
                id: colorRectangle
                height: units.gu(0.4)
                color: root.notebookColor
                Layout.fillWidth: true
            }

            Rectangle {
                anchors { top: colorRectangle.bottom; bottom: parent.bottom }
                color: "#f9f9f9"
                Layout.fillWidth: true
                Layout.maximumWidth: contentRow.width - resourceImage.sourceSize.width

                Label {
                    id: titleLabel
                    anchors { left: parent.left; leftMargin: units.gu(0.5); right: parent.right; top: parent.top; topMargin: units.gu(0.5) }
                    text: root.title
                    font.weight: Font.Light
                    elide: Text.ElideRight
                    color: root.notebookColor
                }

                Label {
                    anchors { left: parent.left; leftMargin: units.gu(0.5); right: parent.right; rightMargin: units.gu(3); top: titleLabel.bottom; topMargin: units.gu(0.5) }
                    text: root.content
                    wrapMode: Text.WordWrap
                    textFormat: Text.StyledText
                    maximumLineCount: 2
                    fontSize: "small"
                    color: "black"
                }

                Label {
                    anchors { right: parent.right; rightMargin: units.gu(1) + resourceImage.width ; bottom: parent.bottom; bottomMargin: units.gu(0.5) }
                    text: Qt.formatDate(root.creationDate)
                    color: "#b3b3b3"
                    fontSize: "small"
                }
            }

            Image {
                id: arrowImage
                anchors { right: resourceImage.left; rightMargin: units.gu(1); verticalCenter: parent.verticalCenter }
                source: Qt.resolvedUrl('../images/arrowRight.png') // TODO: Improve this image. Seriously. It's horrible.
                sourceSize.height: units.gu(4)
            }

            Image {
                id: resourceImage
                anchors { top: colorRectangle.bottom; right: parent.right; bottom: parent.bottom }
                source: root.resource
                sourceSize.height: units.gu(9)
            }

            Rectangle {
                Layout.fillWidth: true
                anchors { bottom: parent.bottom }
                height: units.gu(1.5)
                gradient: Gradient {
                    GradientStop{ position: 0.0; color: "transparent" }
                    GradientStop{ position: 1.0; color: "#d9d9d9" }
                }
            }
        }
    }
}
