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
 * Authored by Andrea Cimitan <andrea.cimitan@canonical.com>
 */

import QtQuick 2.0
import QtTest 1.0
import Ubuntu.Components 0.1
import "../../SystemComponents"
import "utils.js" as UtilsJS

Item {
    width: units.gu(42)
    height: units.gu(75)

    ListModel {
        id: mediaPlayerModel
        ListElement { song: "Mine"; artist: "Taylor Swift"; album: "Speak Now"; albumArt: "MediaPlayer/speak-now.jpg"}
        ListElement { song: "Stony Ground"; artist: "Richard Thompson"; album: "Electric"; albumArt: "MediaPlayer/electric.jpg"}
        ListElement { song: "Los Robots"; artist: "Kraftwerk"; album: "The Man-Machine"; albumArt: "MediaPlayer/the-man-machine.jpg"}
    }

    Flickable {
        id: flickable

        anchors.fill: parent
        contentWidth: column.width
        contentHeight: column.height

        Column {
            id: column

            width: flickable.width
            height: childrenRect.height

            MediaPlayerMenu {
                id: mediaPlayerMenu
                model: mediaPlayerModel
            }
        }
    }

    SignalSpy {
        id: signalSpy
        signalName: "play"
        target: mediaPlayerMenu
    }

    TestCase {
        name: "MediaPlayerMenu"
        when: windowShown

        function test_click() {
            signalSpy.clear()

            var playButton = UtilsJS.findChild(mediaPlayerMenu, "playButton")
            mouseClick(playButton, playButton.width / 2, playButton.height / 2, Qt.LeftButton, Qt.NoModifier, 0)
            compare(signalSpy.count > 0, true, "signal play not triggered")
        }
    }
}
