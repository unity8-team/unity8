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
 * Authored by Nick Dedekind <nick.dedekind@canonical.com>
 */

import QtQuick 2.4
import QtTest 1.0
import Ubuntu.Test 0.1
import Ubuntu.Settings.Menus 0.1

Item {
    width: units.gu(42)
    height: units.gu(75)

    Flickable {
        id: flickable

        anchors.fill: parent
        contentWidth: column.width
        contentHeight: column.height

        Item {
            id: column

            width: flickable.width
            height: childrenRect.height

            PlaybackItemMenu {
                id: playbackItem
            }
        }
    }

    SignalSpy {
        id: signalSpyNext
        signalName: "next"
        target: playbackItem
    }

    SignalSpy {
        id: signalSpyPlay
        signalName: "play"
        target: playbackItem
    }

    SignalSpy {
        id: signalSpyPrevious
        signalName: "previous"
        target: playbackItem
    }

    UbuntuTestCase {
        name: "PlaybackItemMenu"
        when: windowShown

        function init() {
            playbackItem.playing = false;
            playbackItem.canPlay = true;
            playbackItem.canGoNext = true;
            playbackItem.canGoPrevious = true;

            signalSpyNext.clear();
            signalSpyPlay.clear();
            signalSpyPrevious.clear();
        }

        function test_buttons_data() {
            return [
                {tag: 'next:true', signalSpy: signalSpyNext, objectName: "nextButton", enableProp: "canGoNext", enableValue: true},
                {tag: 'next:false', signalSpy: signalSpyNext, objectName: "nextButton", enableProp: "canGoNext", enableValue: false},

                {tag: 'play:true', signalSpy: signalSpyPlay, objectName: "playButton", enableProp: "canPlay", enableValue: true},
                {tag: 'play:false', signalSpy: signalSpyPlay, objectName: "playButton", enableProp: "canPlay", enableValue: false},

                {tag: 'previous:true', signalSpy: signalSpyPrevious, objectName: "previousButton", enableProp: "canGoPrevious", enableValue: true},
                {tag: 'previous:false', signalSpy: signalSpyPrevious, objectName: "previousButton", enableProp: "canGoPrevious", enableValue: false},
            ];
        }

        function test_buttons(data) {
            playbackItem[data.enableProp] = data.enableValue;

            var button = findChild(playbackItem, data.objectName);
            mouseClick(button, button.width / 2, button.height / 2);

            compare(data.signalSpy.count > 0, data.enableValue, data.enableValue ? "signal should be triggered" : "signal should not be triggered");
        }
    }
}
