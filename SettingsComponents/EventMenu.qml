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
import "Event"

BasicMenu {
    property alias name: event.name
    property alias description: event.description
    property alias color: event.color
    property alias date: event.date

    Event {
        id: event
        anchors {
            fill: parent
            topMargin: units.gu(1.5)
            bottomMargin: units.gu(1.5)
            leftMargin: units.gu(2)
            rightMargin: units.gu(2)
        }
    }
}
