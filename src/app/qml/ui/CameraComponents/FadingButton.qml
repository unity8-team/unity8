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

import QtQuick 2.3
import Ubuntu.Components 1.1
import "constants.js" as Const

AbstractButton {
    id: button
    property string iconSource

    property Image __active: icon1
    property Image __inactive: icon2

    onIconSourceChanged: {
        if (__active && __inactive) {
            __inactive.source = iconSource
            __active.opacity = 0.0
        } else icon1.source = iconSource
    }

    Image {
        id: icon1
        anchors.fill: parent
        Behavior on opacity {
            NumberAnimation {
                duration: Const.iconFadeDuration; easing.type: Easing.InOutQuad
            }
        }
    }

    Image {
        id: icon2
        anchors.fill: parent
        opacity: 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: Const.iconFadeDuration; easing.type: Easing.InOutQuad
            }
        }
    }

    Connections {
        target: __active
        onOpacityChanged: if (__active.opacity == 0.0) __inactive.opacity = 1.0
    }

    Connections {
        target: __inactive
        onOpacityChanged: {
            if (__inactive.opacity == 1.0) {
                var swap = __active
                __active = __inactive
                __inactive = swap
            }
        }
    }
}

