/*
 * Copyright 2014 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
*/

import QtQuick 2.0
import Ubuntu.Components 1.0

Item {
    id: root
    clip: true

    signal clicked()

    property real topMarginProgress
    property bool interactive: false
    property real maximizedAppTopMargin
    property bool dropShadow: true

    QtObject {
        id: priv
        property real heightDifference: root.height - appImage.implicitHeight
    }

    BorderImage {
        id: dropShadowImage
        anchors.fill: appImage
        anchors.margins: -units.gu(2)
        source: "graphics/dropshadow.png"
        opacity: root.dropShadow ? .4 : 0
        Behavior on opacity { UbuntuNumberAnimation {} }
        border { left: 50; right: 50; top: 50; bottom: 50 }
    }
    Image {
        id: appImage
        anchors {
            fill: parent
            topMargin: priv.heightDifference * Math.max(0, 1 - root.topMarginProgress)
        }
        source: model.screenshot
        antialiasing: true
    }
    MouseArea {
        anchors.fill: appImage
        enabled: !root.interactive
        onClicked: root.clicked()
    }
}
