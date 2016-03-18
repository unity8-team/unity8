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

    Flickable {
        id: flickable

        anchors.fill: parent
        contentWidth: column.width
        contentHeight: column.height

        Item {
            id: column

            width: flickable.width
            height: childrenRect.height

            UserSessionMenu {
                id: userSessionMenu
                name: i18n.tr("Lola Chang")
                iconSource: Qt.resolvedUrl("../../artwork/avatar.png")
                active: true
            }
            UserSessionMenu {
                id: userSessionMenu2
                name: i18n.tr("Sponge Bob")
                iconSource: Qt.resolvedUrl("../../artwork/avatar.png")
                active: false
                anchors.top: userSessionMenu.bottom
            }
        }
    }

    UbuntuTestCase {
        name: "UserSessionMenu"
        when: windowShown

        function test_name() {
            userSessionMenu.name = "Test User"
            compare(userSessionMenu.name, "Test User", "Cannot set name")
        }

        function test_active() {
            var activeIcon = findChild(userSessionMenu, "activeIcon")
            compare(activeIcon.visible, true, "Active icon should be visible when active")
        }

        function test_inactive() {
            var activeIcon = findChild(userSessionMenu2, "activeIcon")
            compare(activeIcon.visible, false, "Active icon should not be visible when inactive")
        }
    }
}
