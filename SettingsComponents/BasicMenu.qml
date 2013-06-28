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
import Ubuntu.Components.ListItems 0.1 as ListItem

ListItem.Empty {
    id: basicMenu

    property var backgroundColor: "transparent" // FIXME use color instead var when Qt will fix the bug with the binding (loses alpha)

//    ItemStyle.class: "settings-menu"

    implicitHeight: units.gu(7)
    showDivider: !background.visible

    Rectangle {
        id: background
        visible: color.a > 0
        color: basicMenu.backgroundColor
        anchors.fill: parent
        z: -1
    }

    Column {
        id: thinDivider
        visible: !basicMenu.showDivider
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        Rectangle {
            width: parent.width
            height: units.dp(1)
            color: Qt.rgba(0, 0, 0, 0.12)
        }

        Rectangle {
            width: parent.width
            height: units.dp(1)
            color: Qt.rgba(1, 1, 1, 0.1)
        }
    }

    Label {
        id: themeDummy
        visible: false
    }
}
