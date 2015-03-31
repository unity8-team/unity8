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
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1

Item {
    id: root
    implicitWidth: Math.max(height, contentRow.width + units.gu(1))
    property alias text: textField.text
    property alias iconName: icon.name
    property alias iconSource: icon.source
    property string color: "transparent"
    property alias iconColor: icon.color
    property alias horizontalAlignment: textField.horizontalAlignment

    property alias font: textField.font

    property bool active: false

    signal clicked()

    opacity: enabled ? 1 : 0.5

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: root.clicked()
    }

    Rectangle {
        anchors.fill: parent
        color: UbuntuColors.darkGrey
        opacity: root.active || mouseArea.pressed ? 0.2 : 0
    }

    Row {
        id: contentRow
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left; leftMargin: units.gu(0.5) }
        spacing: units.gu(0.5)
        Icon {
            id: icon
            anchors { top: parent.top; bottom: parent.bottom; margins: units.gu(0.5) }
            width: height
            visible: source.toString().length > 0
        }
        Label {
            id: textField
            anchors { top: parent.top; bottom: parent.bottom; margins: units.gu(0.5) }
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.width)
        }
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
