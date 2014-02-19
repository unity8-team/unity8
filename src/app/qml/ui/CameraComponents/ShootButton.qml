/*
 * Copyright (C) 2012 Canonical, Ltd.
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

import QtQuick 2.0
import Ubuntu.Components 0.1

CameraToolbarButton {
    id: button

    states: [
        State { name: "camera"
            PropertyChanges { target: button; iconSource: "assets/shoot.png" }
            PropertyChanges { target: recordOn; opacity: 0.0 }
            PropertyChanges { target: pulseAnimation; running: false }
        },
        State { name: "record_off"
            PropertyChanges { target: button; iconSource: "assets/record_off.png" }
            PropertyChanges { target: recordOn; opacity: 0.0 }
            PropertyChanges { target: pulseAnimation; running: false }
        },
        State { name: "record_on"
            PropertyChanges { target: button; iconSource: "assets/record_off.png" }
            PropertyChanges { target: recordOn; opacity: 1.0 }
            PropertyChanges { target: pulseAnimation; running: true }
        }
    ]

    property int pulsePeriod: 750

    Image {
        id: recordOn
        anchors.fill: parent
        source: "assets/record_on.png"
        Behavior on opacity { NumberAnimation { duration: pulsePeriod } }
    }

    Image {
        id: pulse
        anchors.fill: parent
        source: "assets/record_on_pulse.png"
        opacity: 1.0
        visible: button.state != "camera"

        SequentialAnimation on opacity  {
            id: pulseAnimation
            loops: Animation.Infinite
            alwaysRunToEnd: true
            running: false

            PropertyAnimation {
                from: 1.0
                to: 0.0
                duration: pulsePeriod
            }
            PropertyAnimation {
                from: 0.0
                to: 1.0
                duration: pulsePeriod
            }
        }
    }
}
