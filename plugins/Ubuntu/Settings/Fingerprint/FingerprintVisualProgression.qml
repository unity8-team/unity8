/*
 * Copyright 2016 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtGraphicalEffects 1.0
import QtQuick 2.4
import Ubuntu.Components 1.3

Item {
    id: root
    property double enrollmentProgress
    property string source

    anchors.fill: parent

    Image {
        anchors.top: parent.top
        clip: true
        height: parent.height - (parent.height * enrollmentProgress)
        fillMode: Image.Pad
        verticalAlignment: Image.AlignTop

        sourceSize.width: parent.width
        sourceSize.height: parent.height
        source: root.source

        Behavior on height {
            NumberAnimation { duration: UbuntuAnimation.BriskDuration }
        }
    }

    Image {
        anchors.bottom: parent.bottom
        clip: true
        height: parent.height * enrollmentProgress
        fillMode: Image.Pad
        verticalAlignment: Image.AlignBottom

        sourceSize.width: parent.width
        sourceSize.height: parent.height
        source: root.source

        ColorOverlay {
            width: parent.width
            height: parent.height
            source: parent
            color: "#FF00B4EF"
        }

        Behavior on height {
            NumberAnimation { duration: UbuntuAnimation.BriskDuration }
        }
    }
}
