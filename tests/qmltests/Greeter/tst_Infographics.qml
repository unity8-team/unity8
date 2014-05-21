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

Rectangle {
    width: units.gu(60)
    height: units.gu(80)
    color: "black"

    ListModel {
        id: fakeModel
        ListElement { display: "../../tests/qmltests/Greeter/tst_Infographics/infographics-test-01.svg" }
        ListElement { display: "../../tests/qmltests/Greeter/tst_Infographics/infographics-test-02.svg" }
    }

    Infographics {
        id: infographics
        model: fakeModel

        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
        }

        onTriggered: {
            if (index == 0)
                index = 1;
            else
                index = 0;
        }
    }

    UT.UnityTestCase {
        name: "Infographics"
        when: windowShown
    }
}
