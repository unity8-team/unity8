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
    property alias maximumDate: calendar.maximumDate
    property alias minimumDate: calendar.minimumDate
    property alias currentDate: calendar.currentDate

    text: ""
    implicitHeight: label.height + calendar.height + units.gu(4)

    Label {
        id: label
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: units.gu(2)
        }
        text: (calendar.currentDate.getMonth() + 1) + " " + calendar.currentDate.getFullYear()
        font.weight: Font.DemiBold
    }

    Calendar {
        id: calendar
        anchors {
            left: parent.left
            right: parent.right
            top: label.bottom
        }
    }
}
