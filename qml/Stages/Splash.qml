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
*/

import QtQuick 2.0
import Ubuntu.Components 0.1
import "../Components"

Rectangle {
    id: root
    color: "black"

    property string name: ""
    property url image: ""

    UbuntuShape {
        id: iconShape
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -units.gu(4)
        width: units.gu(8)
        height: units.gu(7.5)

        radius: "medium"
        borderSource: "none"

        image: Image {
            id: iconImage
            sourceSize.width: iconShape.width
            sourceSize.height: iconShape.height
            source: root.image
            fillMode: Image.PreserveAspectCrop
        }
    }

    Label {
        text: root.name
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: iconShape.bottom
        anchors.topMargin: units.gu(2)
        fontSize: "large"
    }

    WaitingDots {
        visible: parent.visible
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: units.gu(12)
    }

    Label {
        id: timerLabel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: units.gu(6)
        fontSize: "large"
        property int secs: ms / 1000
        property int ms: 0
        property string msStr: pad((ms % 1000).toString(), 3)
        text: secs + ":" + msStr

        function pad (str, max) {
            print("padding", str, str.length, max)
            return str.length < max ? pad("0" + str, max) : str;
        }
    }

    Timer {
        interval: 10
        running: true
        repeat: true
        property var startTime: null
        Component.onCompleted: startTime = new Date()
        onTriggered: {
            var nowTime = new Date()
            var elapsedMillis = nowTime.getTime() - startTime.getTime()
            timerLabel.ms = elapsedMillis
        }
    }


    MouseArea {
        anchors.fill: parent
        enabled: parent.visible
        // absorb all mouse events
    }
}
