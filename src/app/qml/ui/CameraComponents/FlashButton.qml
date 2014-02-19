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
import "constants.js" as Const

Item {
    id: button

    property bool flashAllowed: true
    property bool torchMode: false
    property string flashState: "off"
    signal clicked()

    CrossFadingButton {
        id: flash
        anchors.fill: parent
        iconSource: (flashState == "off") ? "assets/flash_off.png" :
                    ((flashState == "on") ? "assets/flash_on.png" : "assets/flash_auto.png")
        onClicked: button.clicked()
        enabled: !torchMode
    }

    CrossFadingButton {
        id: torch
        anchors.fill: parent
        iconSource: (flashState == "on") ? "assets/torch_on.png" : "assets/torch_off.png"
        enabled: torchMode
        onClicked: button.clicked()
    }

    states: [
        State { name: "flash"; when: !torchMode
            PropertyChanges { target: flash; opacity: 1.0 }
            PropertyChanges { target: torch; opacity: 0.0 }
        },
        State { name: "torch"; when: torchMode
            PropertyChanges { target: flash; opacity: 0.0 }
            PropertyChanges { target: torch; opacity: 1.0 }
        }
    ]

    transitions: [
        Transition { from: "flash"; to: "torch";
            SequentialAnimation {
                NumberAnimation {
                    target: flash; property: "opacity";
                    duration: Const.iconFadeDuration; easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: torch; property: "opacity";
                    duration: Const.iconFadeDuration; easing.type: Easing.InOutQuad
                }
            }
        },
        Transition { from: "torch"; to: "flash";
            SequentialAnimation {
                NumberAnimation {
                    target: torch; property: "opacity";
                    duration: Const.iconFadeDuration; easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: flash; property: "opacity";
                    duration: Const.iconFadeDuration; easing.type: Easing.InOutQuad
                }
            }
        }
    ]
}
