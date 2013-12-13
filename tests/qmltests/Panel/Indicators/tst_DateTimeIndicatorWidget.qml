/*
 * Copyright 2013 Canonical Ltd.
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
import QMenuModel 0.1
import "../../../../Panel/Indicators"

Item {
    id: testView
    width: units.gu(40)
    height: units.gu(70)

    DateTimeIndicatorWidget {
        id: widget

        anchors {
            left: parent.left
            top: parent.top
        }

        busName: "test"
        actionsObjectPath: "test"
        deviceMenuObjectPath: "test"

        rootMenuType: ""

        iconSize: units.gu(3.2)
        height: units.gu(3)

        rootActionState {
            rightLabel: "foo"
        }
    }

    SignalSpy {
        id: updateSpy
        signalName: "currentDateChanged"
    }

    UT.UnityTestCase {
        name: "DateTimeIndicatorWidget"
        when: windowShown

        function init() {
            updateSpy.target = findChild(widget, "clockLabel");
        }

        function cleanup() {
            widget.rootActionState.rightLabel = "foo";
            updateSpy.clear();
        }

        function test_triggerUpdate() {
            widget.rootActionState.rightLabel = "bar";

            updateSpy.wait();
        }

        function test_currentTime() {
            widget.rootActionState.rightLabel = "bar";

            var label = findChild(widget, "clockLabel");

            var dateObj = label.currentDate;
            var timeString = Qt.formatTime(dateObj);

            compare(label.text, timeString, "Not the expected time");
        }
    }
}
