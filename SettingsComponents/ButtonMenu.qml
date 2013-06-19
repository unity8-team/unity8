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
    property alias text: label.text
    property alias buttonText: button.text

//    ItemStyle.class: "settings-menu button-menu"

    Component.onCompleted: button.clicked.connect(clicked)

    Label {
        id: label
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: units.gu(2)
        }
    }

    Button {
        id: button
        width: units.gu(20)
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: units.gu(2)
        }
    }
}
