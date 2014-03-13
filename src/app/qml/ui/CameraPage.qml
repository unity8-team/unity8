/*
 * Copyright: 2013 Canonical, Ltd
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

import QtQuick 2.0
import Ubuntu.Components 0.1
import QtMultimedia 5.0
import QtQuick.Window 2.0
import Evernote 0.1

Page {
    id: root
    property var note
    property int position

    tools: ToolbarItems {
        locked: true
        opened: true
        ToolbarButton {
            text: "Shoot"
            iconName: "camera-symbolic"
            onTriggered: camera.imageCapture.captureToLocation(cameraHelper.importLocation);
        }
    }

    Camera {
        id: camera
        flash.mode: Camera.FlashTorch
        focus.focusMode: Camera.FocusContinuous
        focus.focusPointMode: Camera.FocusPointAuto

        imageCapture {

            onImageSaved: {
                if (videoOutput.orientation != 0) {
                    cameraHelper.rotate(path, -videoOutput.orientation)
                }

                root.note.attachFile(root.position, path)
                print("got image", path)
                pagestack.pop();
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
    }
}
