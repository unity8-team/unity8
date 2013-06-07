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
import "../../SettingsComponents"
import "utils.js" as UtilsJS

Item {
    width: units.gu(42)
    height: units.gu(75)

    Flickable {
        id: flickable

        anchors.fill: parent
        contentWidth: column.width
        contentHeight: column.height

        Column {
            id: column

            width: flickable.width
            height: childrenRect.height

            UserSessionMenu {
                id: userSessionMenu
                name: i18n.tr("Lola Chang")
                icon: Qt.resolvedUrl("avatar.png")
                active: true
            }
        }
    }

    TestCase {
        name: "UserSessionMenu"
        when: windowShown

        function test_name() {
            userSessionMenu.name = "Test User"
            compare(userSessionMenu.name, "Test User", "Cannot set name")
            compare(userSessionMenu.text, "Test User", "Text property of ListItem did not change")
        }

        function test_active() {
            var activeIcon = UtilsJS.findChild(userSessionMenu, "activeIcon")
            userSessionMenu.active = false
            compare(activeIcon.visible, false, "Cannot disable the active icon element")
            userSessionMenu.active = true
            compare(activeIcon.visible, true, "Cannot enable the active icon element")
        }
    }
}
