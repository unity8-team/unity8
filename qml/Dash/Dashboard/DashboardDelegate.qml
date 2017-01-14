/*
 * Copyright (C) 2017 Canonical, Ltd.
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

import QtQuick 2.4
import Ubuntu.Components 1.3

Text {
    objectName: "delegate" + index
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    text: model.name + " (" + index + ")" + (model.content ? "\n" + eval(model.content) : "")
    color: model.headerColor ? model.headerColor : "white"
    
    width: parent.width
    height: Math.max(units.gu(8), Math.floor(Math.random() * 300)) // FIXME calculate
    
    Rectangle {
        anchors.fill: parent
        radius: units.gu(.5)
        color: UbuntuColors.jet
        opacity: 0.2
    }
    
    Timer {
        running: model.ttl
        repeat: running
        interval: running ? model.ttl : 0
        onTriggered: parent.text = eval(model.content)
    }
}
