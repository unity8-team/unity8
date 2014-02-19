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

Item {
    id: snapshotRoot
    property alias source: snapshot.source
    property alias sliding: shoot.running
    property int orientation
    property ViewFinderGeometry geometry
    property bool deviceDefaultIsPortrait: true

    Item {
        id: container
        anchors.left: parent.left
        anchors.right: parent.right
        height:parent.height
        y: 0

        Image {
            id: snapshot
            anchors.centerIn: parent

            asynchronous: true
            opacity: 0.0
            fillMode: Image.PreserveAspectFit
            smooth: false
            width: deviceDefaultIsPortrait ? geometry.height :  geometry.width
            height: deviceDefaultIsPortrait ? geometry.width : geometry.height
            sourceSize.width: width
            sourceSize.height: height

            onStatusChanged: if (status == Image.Ready) shoot.restart()
        }
    }

    SequentialAnimation {
        id: shoot
        PropertyAction { target: snapshot; property: "opacity"; value: 1.0 }
        ParallelAnimation {
            NumberAnimation { target: container; property: "y";
                              to: container.parent.height; duration: 500; easing.type: Easing.InCubic }
            SequentialAnimation {
                PauseAnimation { duration: 0 }
                NumberAnimation { target: snapshot; property: "opacity";
                                  to: 0.0; duration: 500; easing.type: Easing.InCubic }
            }
        }

        PropertyAction { target: snapshot; property: "opacity"; value: 0.0 }
        PropertyAction { target: snapshot; property: "source"; value: ""}
        PropertyAction { target: container; property: "y"; value: 0 }
    }
}
