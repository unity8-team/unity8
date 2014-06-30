/*
 * Copyright 2014 Canonical Ltd.
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
import ".."
import "../../../qml/Greeter"
import Ubuntu.Components 0.1
import Unity.Test 0.1 as UT
import Infographics 0.1 as InfographicsModule

Rectangle {
    width: units.gu(60)
    height: units.gu(80)
    color: "#888a85"

    Infographics {
        id: infographics
        model: InfographicsModule.InfographicList
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
        }
        height: width
    }

    SignalSpy {
        id: triggeredSpy
        target: infographics
        signalName: "triggered"
    }

    UT.UnityTestCase {
        name: "Infographics"
        when: windowShown

        property var image: findChild(infographics, "image")

        function test_triggered() {
            triggeredSpy.clear();
            var oldImage = image.source;
            mouseDoubleClick(infographics, infographics.width / 2, infographics.height / 2);
            triggeredSpy.wait()
            verify(image.source != oldImage);
        }
    }
}
