/*
 * Copyright (C) 2014 Canonical, Ltd.
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
import Ubuntu.Components 1.3

/* FIXME: This component is duplicating the UbuntuShape from the SDK, but shapes more
 * general (Item-based) components. This ability should be incorporated into the SDK's
 * UbuntuShape so this file can be removed.
 * Bug: https://bugs.launchpad.net/tavastia/+bug/1089595
 */
Item {
    property alias radius: shape.radius
    property alias image: shaderEffectSource.sourceItem

    ShaderEffectSource {
        id: shaderEffectSource
        anchors.centerIn: parent // Placed under shape, so it's hidden
        hideSource: true
    }

    UbuntuShape {
        id: shape
        source: shaderEffectSource
        anchors.fill: parent
        sourceFillMode: UbuntuShape.PreserveAspectCrop
    }
}
