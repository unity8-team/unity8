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
import "../../Ubuntu/SettingsComponents/Calendar"
import "utils.js" as UtilsJS

Item {
    width: units.gu(42)
    height: units.gu(75)

    property var date1: new Date(2012, 3, 10)
    property var date2: new Date(2013, 3, 10)
    property var date3: new Date(2013, 4, 10)
    property var date4: new Date(2013, 4, 10)
    property var date5: new Date(2013, 5, 10)
    property var date6: new Date(2014, 5, 10)

    Label {
        id: label
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: units.gu(2)
        }
        height: units.gu(5)
        color: "#757373"
        fontSize: "large"
        text: Qt.formatDate(calendar.currentDate, "MMMM") + " " + calendar.currentDate.getFullYear()
    }

    Calendar {
        id: calendar
        anchors {
            left: parent.left
            right: parent.right
            top: label.bottom
        }
        maximumDate: new Date(2013, 6, 10)
        minimumDate: new Date(2013, 2, 10)
        selectedDate: new Date(2013, 4, 10)
    }

    TestCase {
        name: "Calendar"
        when: windowShown

        function test_collapsed() {
            calendar.collapsed = true
            compare(calendar.interactive, false, "Calendar should not be interactive")
            var collapsedHeight = calendar.height
            calendar.collapsed = false
            verify(calendar.height > collapsedHeight * 4 && calendar.height < collapsedHeight * 6, "Height did not expand properly")
            compare(calendar.interactive, true, "Calendar should be interactive")
        }

        function test_currentDate_data() {
            return [
                {date: date4},
                {date: date3},
            ];
        }

        function test_currentDate(data) {
            calendar.currentDate = data.date
            compare(calendar.currentItem.monthStart.getMonth(), data.date.getMonth(), "currentItem did not change")
        }

        function test_firstDayOfWeek_data() {
            return [
                {tag: 'Thursday', firstDayOfWeek: 5, item1: 6},
                {tag: 'Sunday', firstDayOfWeek: 0, item1: 1},
            ];
        }

        function test_firstDayOfWeek(data) {
            var dayItem1 = UtilsJS.findChild(calendar, "dayItem1")

            calendar.firstDayOfWeek = data.firstDayOfWeek
            compare(dayItem1.dayStart.getDay(), data.item1, "Cannot set firstDayOfWeek")
        }

//        function test_maximumDate_data() {
//            return [
//                {date: date6, count: 5},
//                {date: date5, count: 4},
//            ];
//        }

//        function test_maximumDate(data) {
//            calendar.maximumDate = data.date
//            compare(calendar.count, data.count, "The number of months should have changed")
//        }

//        function test_minimumDate_data() {
//            return [
//                {date: date1, count: 4},
//                {date: date2, count: 3},
//            ];
//        }

//        function test_minimumDate(data) {
//            calendar.minimumDate = data.date
//            compare(calendar.count, data.count, "The number of months should have changed")
//        }

        function test_selectedDate_data() {
            return [
                {date: date4},
                {date: date3},
            ];
        }

        function test_selectedDate(data) {
            calendar.selectedDate = data.date
            compare(calendar.currentItem.monthStart.getMonth(), data.date.getMonth(), "currentItem did not change")
        }
    }
}
