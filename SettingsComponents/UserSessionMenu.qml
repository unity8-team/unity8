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

BasicMenu {
    id: userSessionMenu

    property alias name: userSessionMenu.text
    property alias active: activeIcon.visible

//    ItemStyle.class: "settings-menu usersession-menu"

    Rectangle {
        id: activeIcon
        objectName: "activeIcon"
        anchors {
            right: parent.right
            rightMargin: units.gu(2)
            verticalCenter: parent.verticalCenter
        }
        width: image.width + units.gu(1.5)
        height: image.height + units.gu(1.5)
        radius: width / 2
        antialiasing: true
        color: "#d0d0d0"
        visible: false

        Image {
            id: image
            source: "UserSession/CheckMark.png"
            anchors.centerIn: parent
        }
    }
}
