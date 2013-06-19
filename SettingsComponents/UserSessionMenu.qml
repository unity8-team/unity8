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

    property alias name: label.text
    property alias active: activeIcon.visible
    property alias icon: iconImage.source

//    ItemStyle.class: "settings-menu usersession-menu"

    Row {
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: units.gu(2)
        }
        spacing: units.gu(1)

        UbuntuShape {
            width: units.gu(5)
            height: width

            image: Image {
                id: iconImage
            }
        }

        Label {
            id: label
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Rectangle {
        id: activeIcon
        objectName: "activeIcon"
        anchors {
            right: parent.right
            rightMargin: units.gu(2)
            verticalCenter: parent.verticalCenter
        }
        width: checkMark.width + units.gu(1.5)
        height: checkMark.height + units.gu(1.5)
        radius: width / 2
        antialiasing: true
        color: "#d0d0d0"
        visible: false

        Image {
            id: checkMark
            source: "UserSession/CheckMark.png"
            anchors.centerIn: parent
        }
    }
}
