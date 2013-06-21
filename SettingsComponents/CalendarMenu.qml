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
import Ubuntu.Components 0.1
import "Calendar"

BasicMenu {
    id: calendarMenu

    property alias collapsed: calendar.collapsed
    property alias currentDate: calendar.currentDate
    property alias firstDayOfWeek: calendar.firstDayOfWeek
    property alias maximumDate: calendar.maximumDate
    property alias minimumDate: calendar.minimumDate
    property alias selectedDate: calendar.selectedDate

//    ItemStyle.class: "settings-menu calendar-menu"

    implicitHeight: label.height + calendar.height + units.gu(2) + units.dp(2)

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
        ItemStyle.class: "label label-date"
        text: Qt.formatDate(calendar.currentDate, "MMMM") + " " + calendar.currentDate.getFullYear()
    }

    Calendar {
        id: calendar
        objectName: "calendar"
        anchors {
            left: parent.left
            right: parent.right
            top: label.bottom
            leftMargin: units.gu(2)
            rightMargin: units.gu(2)
        }
    }
}
