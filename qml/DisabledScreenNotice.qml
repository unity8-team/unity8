/*
 * Copyright (C) 2016 Canonical, Ltd.
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

import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Gestures 0.1
import Unity.Session 0.1
import QtQuick.Window 2.2
import "Components"
import Aethercast 0.1

Item {
    id: root

    property bool infoNoteDisplayed: true

    // For testing
    property var screen: Screen
    property var orientationLock: OrientationLock

    DeviceConfiguration {
        id: deviceConfiguration
        name: applicationArguments.deviceName
    }

    Item {
        id: contentContainer
        objectName: "contentContainer"
        anchors.centerIn: parent
        height: rotation == 90 || rotation == 270 ? parent.width : parent.height
        width: rotation == 90 || rotation == 270 ? parent.height : parent.width

        property int savedOrientation: deviceConfiguration.primaryOrientation == deviceConfiguration.useNativeOrientation
                                       ? (root.width > root.height ? Qt.LandscapeOrientation : Qt.PortraitOrientation)
                                       : deviceConfiguration.primaryOrientation

        rotation: {
            var usedOrientation = root.screen.orientation;

            if (root.orientationLock.enabled) {
                usedOrientation = savedOrientation;
            }

            savedOrientation = usedOrientation;

            switch (usedOrientation) {
            case Qt.PortraitOrientation:
                return 0;
            case Qt.LandscapeOrientation:
                return 270;
            case Qt.InvertedPortraitOrientation:
                return 180;
            case Qt.InvertedLandscapeOrientation:
                return 90;
            }

            return 0;
        }
        transformOrigin: Item.Center

        VirtualTouchPad {
            anchors.fill: parent

            onPressedChanged: {
                if (pressed && infoNoteDisplayed) {
                    infoNoteDisplayed = false;
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#3b3b3b"
        }

        Item {
            objectName: "infoNoticeArea"
            anchors.fill: parent
            opacity: infoNoteDisplayed ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                UbuntuNumberAnimation { }
            }

            Column {
                anchors.centerIn: parent
                width: parent.width - units.gu(8)
                spacing: units.gu(4)

                Label {
                    id: text
                    text: i18n.tr("Your device is now connected to an external display. Use this screen as a touch pad to interact with the pointer.")
                    color: "white"
                    width: parent.width
                    fontSize: "large"
                    wrapMode: Text.Wrap
                }
                Icon {
                    height: units.gu(8)
                    width: height
                    name: "input-touchpad-symbolic"
                    color: "white"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        InputMethod {
            id: inputMethod
            objectName: "inputMethod"
            anchors.fill: parent
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: topPanel.y > -topPanel.height
        onClicked: {
            topPanel.collapse()
        }
    }

    Rectangle {
        id: topPanel
        anchors { left: parent.left; right: parent.right }
        height: units.gu(10)
        color: "#292929"
        y: -height

        RowLayout {
            anchors.fill: parent
            anchors.margins: units.gu(2)

            Label {
                text: "External display"
                Layout.fillWidth: true
                color: "white"
            }
            Button {
                text: "Disconnect"
                color: UbuntuColors.green
                onClicked: {
                    AethercastManager.disconnectAll()
                    topPanel.collapse();
                }
            }
        }

        function collapse() {
            snapAnimation.targetY = -topPanel.height;
            snapAnimation.start();
        }

        function expand() {
            snapAnimation.targetY = 0
            snapAnimation.start();
        }

        UbuntuNumberAnimation {
            id: snapAnimation
            property int targetY
            target: topPanel
            property: "y"
            to: targetY
        }
    }

    DirectionalDragArea {
        id: topDragArea
        direction: Direction.Downwards
        width: parent.width
        height: units.gu(1)
        onDistanceChanged: topPanel.y = Math.min(-topPanel.height + distance, 0)
        onDraggingChanged: {
            print("dragging changed")
            if (!dragging) {
                if (topPanel.y > -topPanel.height / 2) {
                    topPanel.expand()
                } else {
                    topPanel.collapse()
                }
            }
        }
    }
}
