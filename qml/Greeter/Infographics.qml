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

import QtQuick 2.0
import Ubuntu.Components 0.1
import "../Components"

Item {
    id: root

    property var model
    property int index: 0

    implicitHeight: width

    signal triggered()

    CrossFadeInfographics {
        objectName: "image"
        anchors.centerIn: parent
        height: width
        width: parent.width
        source: model.get(index).display
        fadeDuration: UbuntuAnimation.SleepyDuration
        fadeOutCurrentImage: true

        MouseArea {
            anchors.fill: parent
            onDoubleClicked: root.triggered()
        }
    }
}

