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
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Settings.Components 0.1

ListItem.Empty {
    id: menu

    property alias collapsed: calendar.collapsed
    property alias currentDate: calendar.currentDate
    property alias firstDayOfWeek: calendar.firstDayOfWeek
    property alias maximumDate: calendar.maximumDate
    property alias minimumDate: calendar.minimumDate
    property alias selectedDate: calendar.selectedDate

    __height: column.height

    Column {
        id: column

        height: childrenRect.height + units.gu(1.5)
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: units.gu(1)
            leftMargin: menu.__contentsMargins
            rightMargin: menu.__contentsMargins
        }
        spacing: units.gu(1)

        Label {
            id: label
            anchors {
                left: parent.left
                right: parent.right
            }
            fontSize: "large"
            text: i18n.ctr("%1=month name, %2=4-digit year", "%1 %2")
                      .arg(Qt.locale().standaloneMonthName(calendar.currentDate.getMonth(), Locale.LongFormat))
                      .arg(calendar.currentDate.getFullYear())
        }

        Calendar {
            id: calendar
            objectName: "calendar"
            anchors {
                left: parent.left
                right: parent.right
            }
        }
    }
}
