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
import QtTest 1.0
import Unity.Test 0.1 as UT
import Utils 0.1

Rectangle {
    id: main
    width: 300
    height: 300

    MouseArea {
        id: mouseArea
        anchors.fill: parent
    }

    SignalSpy {
        id: mouseAreaPressed
        target: mouseArea
        signalName: "onPressed"
    }

    SignalSpy {
        id: mouseAreaReleased
        target: mouseArea
        signalName: "onReleased"
    }

    SignalSpy {
        id: mouseAreaClicked
        target: mouseArea
        signalName: "clicked"
    }

    PassthroughMouseArea {
        id: passThroughArea
        anchors.fill: parent
    }

    SignalSpy {
        id: passThroughAreaPressed
        target: passThroughArea
        signalName: "onPressed"
    }

    SignalSpy {
        id: passThroughAreaReleased
        target: passThroughArea
        signalName: "onReleased"
    }

    SignalSpy {
        id:passThroughAreaClicked
        target: passThroughArea
        signalName: "clicked"
    }

    UT.UnityTestCase {
        name: "PassthroughMouseAreaTest"
        when: windowShown

        function init() {
            mouseAreaClicked.clear();
            mouseAreaPressed.clear();
            mouseAreaReleased.clear();

            passThroughAreaClicked.clear();
            passThroughAreaPressed.clear();
            passThroughAreaReleased.clear();

            mouseArea.enabled = true;
            passThroughArea.enabled = true;
        }

        function test_press_release_click_data() {
            return [
                { tag: "mouseArea::enabled", enabled: true },
                { tag: "mouseArea::disabled", enabled: false },
            ];
        }

        function test_press_release_click(data) {
            mouseArea.enabled = data.enabled;
            var expectedMouseArea = data.enabled ? 1 : 0;

            touchPress(main, main.width / 2, main.height / 2);
            compare(mouseAreaPressed.count, expectedMouseArea, "Mouse area should have been pressed");
            compare(passThroughAreaPressed.count, 1, "Passthrough area should have been pressed");
            compare(mouseAreaReleased.count, 0, "Mouse area should not have been released");
            compare(passThroughAreaReleased.count, 0, "Passthrough area should not have been released");

            touchRelease(main, main.width / 2, main.height / 2);
            compare(mouseAreaReleased.count, expectedMouseArea, "Mouse area should been released");
            compare(passThroughAreaReleased.count, 1, "Passthrough area should been released");
            compare(mouseAreaPressed.count, expectedMouseArea, "Mouse area should not have been pressed again");
            compare(passThroughAreaPressed.count, 1, "Passthrough area should not have been pressed again");

            compare(mouseAreaClicked.count, expectedMouseArea, "Mouse area should have been released");
            compare(passThroughAreaClicked.count, 1, "Passthrough should have been pressed");
        }
    }
}
