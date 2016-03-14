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

            EventMenu {
                id: eventMenu
                eventColor: "yellow"
                text: "Lunch with Lola"
                time: "1:10 PM"
            }
        }
    }

    SignalSpy {
        id: signalSpyTriggered
        signalName: "triggered"
        target: eventMenu
    }

    TestCase {
        name: "EventMenu"
        when: windowShown

        function test_eventColor() {
            eventMenu.eventColor = "red"
            compare(eventMenu.eventColor, "#ff0000", "Cannot set color")
        }

        function test_name() {
            eventMenu.text = "Gym"
            compare(eventMenu.text, "Gym", "Cannot set name")
        }

        function test_time() {
            eventMenu.time = "6:30 PM"
            compare(eventMenu.time, "6:30 PM", "Cannot set date")
        }

        function test_triggered() {
            mouseClick(eventMenu, eventMenu.width / 2, eventMenu.height / 2);
            compare(signalSpyTriggered.count > 0, true, "should have been triggered");
        }
    }
}
