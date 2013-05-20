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
                song: "Mine";
                artist: "Taylor Swift";
                album: "Speak Now";
                albumArt: "../../SystemComponents/MediaPlayer/speak-now.jpg"
            }
        }
    }

    SignalSpy {
        id: signalSpyNext
        signalName: "next"
        target: mediaPlayerMenu
    }

    SignalSpy {
        id: signalSpyPlay
        signalName: "play"
        target: mediaPlayerMenu
    }

    SignalSpy {
        id: signalSpyPrevious
        signalName: "previous"
        target: mediaPlayerMenu
    }

    TestCase {
        name: "MediaPlayerMenu"
        when: windowShown

        function test_buttons_data() {
            return [
                {tag: 'next', signalSpy: signalSpyNext, objectName: "nextButton"},
                {tag: 'play', signalSpy: signalSpyPlay, objectName: "playButton"},
                {tag: 'previous', signalSpy: signalSpyPrevious, objectName: "previousButton"},
            ];
        }

        function test_buttons(data) {
            data.signalSpy.clear()

            var button = UtilsJS.findChild(mediaPlayerMenu, data.objectName)
            mouseClick(button, button.width / 2, button.height / 2, Qt.LeftButton, Qt.NoModifier, 0)
            compare(data.signalSpy.count > 0, true, "signal not triggered")
        }
    }
}
