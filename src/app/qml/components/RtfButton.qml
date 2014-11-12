/*
 * Copyright: 2013-2014 Canonical, Ltd
 *
 * This file is part of reminders
 *
 * reminders is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.3
import Ubuntu.Components 1.1

Item {
    id: root
    property alias text: textField.text
    property alias iconName: icon.name
    property alias iconSource: icon.source
    property string color: "transparent"
    property alias horizontalAlignment: textField.horizontalAlignment

    property alias font: textField.font

    property bool active: false

    signal clicked()

    opacity: enabled ? 1 : 0.5

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }

    Rectangle {
        anchors.fill: parent
        color: UbuntuColors.darkGrey
        opacity: root.active ? 0.2 : 0
    }

    Label {
        id: textField
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        width: parent.width
        elide: Text.ElideRight
    }

    Icon {
        id: icon
        anchors.fill: parent
        anchors.margins: units.gu(0.5)
    }

    UbuntuShape {
        id: colorRect
        anchors.fill: parent
        anchors.margins: units.gu(0.5)
        color: root.color
        radius: "small"
        visible: root.color != "transparent"
    }
}
