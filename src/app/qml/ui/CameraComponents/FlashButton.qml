/*
 * Copyright (C) 2012 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import "constants.js" as Const

Item {
    id: button

    property bool flashAllowed: true
    property string flashState: "off"
    signal clicked()

    CrossFadingButton {
        id: flash
        anchors.fill: parent
        iconSource: (flashState == "off") ? "assets/flash_off.png" :
                    ((flashState == "on") ? "assets/flash_on.png" : "assets/flash_auto.png")
        onClicked: button.clicked()
    }
}
