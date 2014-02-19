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

Image {
    property var center
    source: "assets/focus_ring.png"

    Behavior on opacity { NumberAnimation { duration: 500 } }
    onCenterChanged: {
        x = center.x - focusRing.width * 0.5
        y = center.y - focusRing.height * 0.5
        opacity = 1.0
        restartTimeout()
    }

    function restartTimeout()
    {
        focusRingTimeout.restart()
    }

    Timer {
        id: focusRingTimeout
        interval: 2000
        onTriggered: focusRing.opacity = 0.0
    }
}
