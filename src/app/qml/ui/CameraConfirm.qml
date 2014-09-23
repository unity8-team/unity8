/*
 * Copyright: 2014 Canonical, Ltd
 *
 * This file is part of reminders-app
 *
 * reminders-app is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.3
import Ubuntu.Components 1.1
import Evernote 0.1

Page {
    id: confirmPage

    property var imageLocation

    Image {
    	source: imageLocation
    	anchors {
            fill: parent;
        }
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: units.gu(6)
        color: "white"

        Icon {
            name: "back"

            height: units.gu(3)
            width: height

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: units.gu(2)
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    cameraHelper.removeTemp();
                    pagestack.pop();
                }
            }
        }

        Icon {
            name: "tick"

            height: units.gu(3)
            width: height

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: units.gu(2)
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.imageConfirmed();
                    pagestack.pop();
                }
            }
        }
    }
}
