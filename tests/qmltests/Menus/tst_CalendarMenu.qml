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

    property var date1: new Date(2012, 2, 10)
    property var date2: new Date(2013, 5, 10)
    property var date3: new Date(2014, 6, 10)

    Flickable {
        id: flickable

        anchors.fill: parent
        contentWidth: column.width
        contentHeight: column.height

        Item {
            id: column

            width: flickable.width
            height: childrenRect.height

            CalendarMenu {
                id: calendarMenu
            }
        }
    }

    UbuntuTestCase {
        name: "CalendarMenu"
        when: windowShown

        property var calendar: findChild(calendarMenu, "calendar")

        function test_collapsed() {
            calendarMenu.collapsed = true
            compare(calendar.collapsed, true, "Cannot set collapsed")
        }

        function test_currentDate() {
            calendarMenu.currentDate = date2
            compare(calendar.currentDate, date2, "Cannot set currendDate")
        }

        function test_firstDayOfWeek() {
            calendarMenu.firstDayOfWeek = 5
            compare(calendar.firstDayOfWeek, 5, "Cannot set firstDayOfWeek")
        }

        function test_maximumDate() {
            calendarMenu.maximumDate = date3
            compare(calendar.maximumDate, date3, "Cannot set maximumDate")
        }

        function test_minimumDate() {
            calendar.minimumDate = date1
            compare(calendar.minimumDate, date1, "Cannot set minimumDate")
        }

        function test_selectedDate() {
            calendar.selectedDate = date2
            compare(calendar.selectedDate, date2, "Cannot set selectedDate")
        }
    }
}
