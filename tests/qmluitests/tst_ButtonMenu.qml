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
import "../../SystemComponents"

Item {
    id: root
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

            ButtonMenu {
                id: buttonMenu
                text: i18n.tr("Button")
                controlText: i18n.tr("Hello world!")
            }
        }
    }

    SignalSpy {
        id: signalSpy
        signalName: "clicked"
        target: buttonMenu.control
    }

    TestCase {
        name: "ButtonMenu"
        when: windowShown

        function test_click() {
            signalSpy.clear()

            var button = buttonMenu.control
            mouseClick(buttonMenu, button.width / 2, button.height / 2, Qt.LeftButton, Qt.NoModifier, 0)
            compare(signalSpy.count > 0, true, "signal clicked not triggered")
        }
    }
}
