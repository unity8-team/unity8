/*
 * Copyright 2013 Canonical Ltd.
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
 * Authored by Nick Dedekind <nick.dedekind@gmail.com>
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem

ListItem.Empty {
    id: menu

    property bool playing: false

    property bool canPlay: false
    property bool canGoNext: false
    property bool canGoPrevious: false

    signal next()
    signal play(bool play)
    signal previous()

    implicitHeight: controlsRow.height + units.gu(2)

    Row {
        id: controlsRow

        anchors {
            top: parent.top
            topMargin: units.gu(1)
            horizontalCenter: parent.horizontalCenter
        }
        spacing: units.gu(2)

        Button {
            objectName: "previousButton"
            width: units.gu(5)
            height: width
            onClicked: menu.previous()
            text: ""
            enabled: canGoPrevious
            anchors.verticalCenter: parent.verticalCenter

            Icon {
                anchors.fill: parent
                anchors.margins: units.gu(1)
                name: "media-skip-backward"
                color: Theme.palette.normal.foregroundText
            }
        }

        Button {
            objectName: "playButton"
            width: units.gu(6)
            height: width
            onClicked: menu.play(!playing)
            text: ""
            enabled: canPlay
            anchors.verticalCenter: parent.verticalCenter

            Icon {
                anchors.fill: parent
                anchors.margins: units.gu(1)
                name: playing ? "media-playback-pause" : "media-playback-start"
                color:  Theme.palette.normal.foregroundText
            }
        }

        Button {
            objectName: "nextButton"
            width: units.gu(5)
            height: width
            onClicked: menu.next()
            text: ""
            enabled: canGoNext
            anchors.verticalCenter: parent.verticalCenter

            Icon {
                anchors.fill: parent
                anchors.margins: units.gu(1)
                name: "media-skip-forward"
                color:  Theme.palette.normal.foregroundText
            }
        }
    }
}
