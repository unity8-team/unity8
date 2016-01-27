/*
 * Copyright 2014 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.1
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.Settings.Components 0.1

ListItem.Empty {
    id: menu

    property alias iconSource: icon.source
    property alias text: label.text
    property alias stateText: stateLabel.text
    property alias progress: progressBar.value
    property bool active: false

    property alias maximum: progressBar.maximumValue

    __height: row.height + units.gu(2)

    RowLayout {
        id: row
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: menu.__contentsMargins
            rightMargin: menu.__contentsMargins
        }
        spacing: units.gu(2)

        UbuntuShapeForItem {
            Layout.preferredWidth: units.gu(6)
            Layout.preferredHeight: units.gu(6)

            image: icon
            Icon {
                id: icon
                objectName: "icon"

                color: {
                    if (String(source).match(/^image:\/\/theme/)) {
                        return theme.palette.normal.backgroundText;
                    }
                    return Qt.rgba(0.0, 0.0, 0.0, 0.0);
                }
            }
        }

        ColumnLayout {
            spacing: units.gu(0.5)

            Label {
                id: label
                objectName: "text"
                Layout.fillWidth: true

                elide: Text.ElideRight
                maximumLineCount: 1
                font.weight: Font.DemiBold
            }

            ProgressBar {
                id: progressBar
                objectName: "progress"
                visible: menu.active
                value: 0.0
                showProgressPercentage: false

                Layout.preferredHeight: units.gu(1)
                Layout.fillWidth: true
            }

            Label {
                id: stateLabel
                objectName: "stateText"
                Layout.fillWidth: true
                visible: menu.active

                fontSize: "x-small"
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }
}
