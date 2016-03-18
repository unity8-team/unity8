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

StandardMenu {
    id: userSessionMenu

    property alias name: userSessionMenu.text
    property bool active: false

    component: Component {
        Rectangle {
            id: activeIcon
            objectName: "activeIcon"
            implicitWidth: checkMark.width + units.gu(1.5)
            implicitHeight: checkMark.height + units.gu(1.5)
            radius: width / 2
            antialiasing: true
            color: theme.palette.normal.backgroundText
            visible: userSessionMenu.active

            Image {
                id: checkMark
                source: "image://theme/tick"
                height: units.gu(2)
                width: height
                anchors.centerIn: parent

                sourceSize {
                    height: height
                    width: width
                }
            }
        }
    }
}
