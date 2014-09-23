/*
 * Copyright: 2013 - 2014 Canonical, Ltd
 *
 * This file is part of reminders-app
 *
 * reminders-app is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.3
import Ubuntu.Components 0.1
import QtMultimedia 5.0
import QtQuick.Window 2.0
import Evernote 0.1

import "CameraComponents"

Page {
    id: root
    property var note
    property int position
    property var imageLocation

    signal imageConfirmed()

    onImageConfirmed: {
        root.note.attachFile(root.position, imageLocation);
        print("got image", imageLocation);
        pagestack.pop();
    }

    tools: ToolbarItems {
        locked: true
        opened: false
    }

    Camera {
        id: camera
        flash.mode: Camera.FlashOff
        focus.focusMode: Camera.FocusContinuous
        focus.focusPointMode: Camera.FocusPointAuto

        property alias currentZoom: camera.digitalZoom
        property alias maximumZoom: camera.maximumDigitalZoom

        Component.onCompleted: cameraHelper.removeTemp();

        imageCapture {
            onImageSaved: {
                if (videoOutput.orientation != 0) {
                    cameraHelper.rotate(path, -videoOutput.orientation)
                }
                imageLocation = path;
                var component = Qt.createComponent(Qt.resolvedUrl("CameraConfirm.qml"));
                var page = component.createObject(root, {imageLocation: imageLocation});
                pagestack.push(page);
            }
        }
    }

    VideoOutput {
        id: videoOutput
        anchors {
            fill: parent
        }
        fillMode: Image.PreserveAspectCrop
        orientation: Screen.primaryOrientation === Qt.PortraitOrientation  ? -90 : 0
        source: camera
        focus: visible

        ViewFinderGeometry {
            id: viewFinderGeometry
            anchors.centerIn: parent

            Item {
                id: itemScale
                visible: false
            }
        }
    }

    Item {
        id: controlsArea
        anchors {
            centerIn: parent;
            fill: parent
        }
        
        ZoomControl {
            id: zoomControl
            maximumValue: camera.maximumZoom
            height: units.gu(4.5)

            anchors {
                left: parent.left; right: parent.right; bottom: toolbar.top; 
                leftMargin: units.gu(0.75); rightMargin: units.gu(0.75); bottomMargin: units.gu(0.5); topMargin: units.gu(0.5)
            }

            visible: camera.maximumZoom > 1

            // Create a two way binding between the zoom control value and the actual camera zoom,
            // so that they can stay in sync when the zoom is changed from the UI or from the hardware
            Binding { target: zoomControl; property: "value"; value: camera.currentZoom }
            Binding { target: camera; property: "currentZoom"; value: zoomControl.value }
        }

        CameraToolbar {
            id: toolbar

            anchors {
                bottom: parent.bottom; left: parent.left; right: parent.right;
                bottomMargin: units.gu(1); leftMargin: units.gu(1); rightMargin: units.gu(1)
            }

            camera: camera
            canCapture: camera.imageCapture.ready
        }
    }
}
