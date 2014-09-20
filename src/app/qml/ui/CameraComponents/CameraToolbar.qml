/*
 * Copyright 2012 - 2014 Canonical Ltd.
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

import QtQuick 2.3
import QtMultimedia 5.0
import Ubuntu.Components 0.1

Item {
    id: toolbar

    property Camera camera

    signal zoomClicked()

    Behavior on opacity { NumberAnimation { duration: 500 } }

    height: middle.height
    property int iconWidth: units.gu(6)
    property int iconHeight: units.gu(5)
    property bool canCapture

    function switchFlashMode() {
        camera.flash.mode = (flashButton.flashState == "off") ? Camera.FlashOn :
        ((flashButton.flashState == "on") ? Camera.FlashAuto : Camera.FlashOff);
    }

    BorderImage {
        id: leftBackground
        anchors {
            left: parent.left; top: parent.top; bottom: parent.bottom; right: middle.left; 
            topMargin: units.dp(2); bottomMargin: units.dp(2) 
        }
        source: "assets/toolbar-left.sci"

        property int iconSpacing: (width - toolbar.iconWidth * children.length) / 3

        FlashButton {
            id: flashButton
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: parent.iconSpacing }

            height: toolbar.iconHeight
            width: toolbar.iconWidth
            enabled: toolbar.opacity > 0.0

            flashState: { switch (camera.flash.mode) {
                case Camera.FlashAuto: return "auto";
                case Camera.FlashOn:
                case Camera.FlashVideoLight: return "on";
                case Camera.FlashOff:
                default: return "off"
            }}

            onClicked: toolbar.switchFlashMode()

            property variant previousFlashMode: Camera.FlashOff
        }
    }

    BorderImage {
        id: middle
        anchors { top: parent.top; bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
        height: shootButton.height + units.gu(1)
        source: "assets/toolbar-middle.sci"

        CameraToolbarButton {
            id: shootButton
            anchors.centerIn: parent
            iconWidth: units.gu(8)
            iconHeight: units.gu(8)
            iconSource: "assets/shoot.png"

            onClicked: camera.imageCapture.captureToLocation(cameraHelper.importLocation);
            enabled: toolbar.canCapture
            opacity: enabled ? 1.0 : 0.5
        }
    }

    BorderImage {
        id: rightBackground
        anchors { 
            right: parent.right; top: parent.top; bottom: parent.bottom; left: middle.right; 
            topMargin: units.dp(2); bottomMargin: units.dp(2) 
        }
        source: "assets/toolbar-right.sci"

        CameraToolbarButton {
            id: closeButton
            anchors.centerIn: parent
            iconWidth: toolbar.iconWidth
            iconHeight: toolbar.iconHeight
            iconSource: "assets/close.png"

            onClicked: pagestack.pop();
        }
    }
}
