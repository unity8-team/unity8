/*
* Copyright 2014 Canonical Ltd.
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
*
* Authored by Andrea Cimitan <andrea.cimitan@canonical.com>
*/

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Settings.Components 0.1
import Ubuntu.Settings.Menus 0.1

Item {
    property string title: "Transfer Components"

    width: units.gu(42)
    height: units.gu(75)

    ListModel {
        id: model
        ListElement {
            text: "File name here"
            state: "Starting…"
            progress: 0
            image: "image://theme/video-x-generic-symbolic"
            active: true
        }
        ListElement {
            text: "proposition.pdf"
            state: "10 seconds remaining"
            progress: 0.7
            image: "../tests/artwork/the-man-machine.jpg"
            active: true
        }
        ListElement {
            text: "electric.jpg"
            state: "Failed, tap to retry"
            progress: 1.0
            image: "../tests/artwork/electric.jpg"
            active: true
        }
        ListElement {
            text: "clubbing-friday.jpg.jpg"
            state: "no state"
            progress: 0.4
            image: "../tests/artwork/speak-now.jpg"
            active: false
        }
    }

    ListView {
        model: model
        anchors.fill: parent

        cacheBuffer: 10000

        delegate: Loader {
            anchors {
                left: parent.left
                right: parent.right
            }
            asynchronous: true

            sourceComponent: TransferMenu {
                text: model.text
                stateText: model.state
                progress: model.progress
                iconSource: model.image
                active: model.active
            }
        }
    }
}
