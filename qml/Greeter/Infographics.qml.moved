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
import Ubuntu.Components 1.1

CrossFadeImage {
    id: root

    property var model

    sourceSize.width: width
    sourceSize.height: height
    source: model.path
    fadeDuration: UbuntuAnimation.SleepyDuration
    fadeStyle: "cross"

    signal triggered()

    onTriggered: model.next()

    MouseArea {
        anchors.centerIn: parent
        width: height
        height: parent.height
        onDoubleClicked: root.triggered();
        onClicked: mouse.accepted = false
        onPressed: mouse.accepted = false
    }
}
