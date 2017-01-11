/*
 * Copyright (C) 2017 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.6
import Ubuntu.Components 1.3

Rectangle {
    id: root
    width: topLayout.childrenRect.width + topLayout.anchors.leftMargin + topLayout.anchors.rightMargin
    height: topLayout.childrenRect.height + topLayout.anchors.topMargin + topLayout.anchors.bottomMargin
    color: UbuntuColors.jet //theme.palette.normal.background
    opacity: .95
    radius: units.gu(.5)

    focus: visible

    Keys.onEscapePressed: enabled = false

    property var model: [
        {
            "name": "Philips",
            "hasPointer": true,
            "workspaces": ["bar", "foo", "baz"]
        },
        {
            "name": "Home project",
            "workspaces": ["a", "b", "c", "d"]
        },
        {
            "name": "Work project",
            "workspaces": ["w", "x", "y", "z", "ž"]
        },
        {
            "name": "Dell P2014H 20",
            "workspaces": ["1", "2", "3", "4", "5", "6", "7", "8", "9", "abc", "def", "ghi"]
        },
        {
            "name": "Sony VPL-DW240",
            "workspaces": ["abc", "def", "ghi"]
        }
    ]

    property int currentScreen: 0
    property int currentWS: 0

    onCurrentScreenChanged: {
        print("Current screen", currentScreen)
        var screen = root.model[root.currentScreen];
        print("Screen name:", screen.name)
        print("Has pointer:", screen.hasPointer || false)
        print("WS list:", screen.workspaces, "\n")
    }

    readonly property int padding: units.gu(1)

    function switchNext() {
        // ...
        enabled = false;
    }

    function switchPrevious() {
        // ...
        enabled = false;
    }

    Component {
        id: screenComponent

        MouseArea {
            width: row.childrenRect.width + padding*4
            height: row.childrenRect.height + padding*2.5
            readonly property bool isCurrent: root.currentScreen == index

            Rectangle {
                anchors.fill: parent
                radius: units.gu(.5)
                color: root.currentScreen == index ? "white" : UbuntuColors.inkstone
                anchors.bottomMargin: -radius
            }

            Row {
                id: row
                anchors.centerIn: parent
                spacing: root.padding

                Label {
                    id: label
                    text: modelData.name
                    color: isCurrent ? UbuntuColors.jet : UbuntuColors.porcelain
                    font.weight: isCurrent ? Font.Normal : Font.Light
                }

                Icon {
                    name: "gps" // FIXME wrong icon
                    width: height
                    height: label.height
                    visible: modelData.hasPointer || false
                }
            }

            onClicked: {
                root.currentScreen = index;
                root.currentWS = -1;
            }
        }
    }

    Component {
        id: workspaceComponent

        Rectangle {
            width: units.gu(12) // FIXME should use the correct aspect ratio
            height: units.gu(7)
            radius: units.gu(.5)
            color: root.currentWS == index ? "white" : UbuntuColors.graphite

            Label {
                anchors.centerIn: parent
                text: modelData
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.currentWS = index;
                    print("Selected WS:", modelData, "with index:", index)
                }
            }
        }
    }

    Column {
        id: topLayout
        anchors.fill: parent
        anchors.margins: root.padding * 2

        Row {
            id: screensRow
            spacing: root.padding
            Repeater {
                model: root.model
                delegate: screenComponent
            }
        }

        Rectangle {
            width: Math.max(childrenRect.width, screensRow.width)
            height: childrenRect.height
            color: UbuntuColors.ash
            Row {
                id: wsRow
                spacing: root.padding
                padding: root.padding
                Repeater {
                    model: root.model[root.currentScreen].workspaces
                    delegate: workspaceComponent
                }
            }
        }
    }
}
