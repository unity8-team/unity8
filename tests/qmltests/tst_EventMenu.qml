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
import Ubuntu.Settings.Menus 0.1

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

            EventMenu {
                id: eventMenu
                eventColor: "yellow"
                name: "Lunch with Lola"
                description: "Some nice Thai food in the bay area"
                date: "1:10 PM"
            }
        }
    }

    TestCase {
        name: "EventMenu"
        when: windowShown

        function test_eventColor() {
            eventMenu.eventColor = "red"
            compare(eventMenu.eventColor, "#ff0000", "Cannot set color")
        }

        function test_name() {
            eventMenu.name = "Gym"
            compare(eventMenu.name, "Gym", "Cannot set name")
        }

        function test_description() {
            eventMenu.description = "Workout with John"
            compare(eventMenu.description, "Workout with John", "Cannot set description")
        }

        function test_date() {
            eventMenu.date = "6:30 PM"
            compare(eventMenu.date, "6:30 PM", "Cannot set date")
        }
    }
}
