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
import "../../SystemComponents/Calendar"
import "utils.js" as UtilsJS

Item {
    width: units.gu(42)
    height: units.gu(75)

    Calendar {
        id: calendar
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        maximumDate: new Date(2013, 6, 10)
        minimumDate: new Date(2013, 2, 10)
        selectedDate: new Date(2013, 4, 10)
    }

    TestCase {
        name: "Calendar"
        when: windowShown

        function test_compressed() {
            calendar.compressed = true
            compare(calendar.height, calendar.__compressedHeight, "Unexpected height")
            compare(calendar.interactive, false, "Calendar should not be interactive")
            calendar.compressed = false
            compare(calendar.height, calendar.__expandedHeight, "Unexpected height")
            compare(calendar.interactive, true, "Calendar should be interactive")
        }

        function test_currentDate() {
            calendar.currentDate = new Date(2013, 5, 10)
            compare(calendar.currentIndex, 3, "currentIndex did not change")
            calendar.currentDate = new Date(2013, 4, 10)
            compare(calendar.currentIndex, 2, "currentIndex did not change")
        }

        function test_firstDayOfWeek() {
            calendar.firstDayOfWeek = 5
            compare(calendar.firstDayOfWeek, 5, "Cannot set firstDayOfWeek")
            calendar.firstDayOfWeek = 0
            compare(calendar.firstDayOfWeek, 0, "Cannot set firstDayOfWeek")
        }

        function test_maximumDate() {
            calendar.maximumDate = new Date(2014, 6, 10)
            compare(calendar.count, 17, "The number of months should have increased")
            calendar.maximumDate = new Date(2013, 6, 10)
            compare(calendar.count, 5, "The number of months should have increased")
        }

        function test_minimumDate() {
            calendar.minimumDate = new Date(2012, 2, 10)
            compare(calendar.count, 17, "The number of months should have increased")
            calendar.minimumDate = new Date(2013, 2, 10)
            compare(calendar.count, 5, "The number of months should have increased")
        }

        function test_selectedDate() {
            calendar.selectedDate = new Date(2013, 5, 10)
            compare(calendar.currentIndex, 3, "currentIndex did not change")
            calendar.selectedDate = new Date(2013, 4, 10)
            compare(calendar.currentIndex, 2, "currentIndex did not change")
        }
    }
}
