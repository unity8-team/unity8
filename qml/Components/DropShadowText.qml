/*
 * Copyright (C) 2015 Canonical, Ltd.
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
import Ubuntu.Components 1.1
import QtGraphicalEffects 1.0 

Item {
    id: root
    property alias clip: label.clip
    property alias color: label.color
    property alias elide: label.elide
    property alias font: label.font
    property alias fontSize: label.fontSize
    property alias text: label.text
    property alias textFormat: label.textFormat
    property alias wrapMode: label.wrapMode
    property alias horizontalAlignment: label.horizontalAlignment
    property alias verticalAlignment: label.verticalAlignment
    implicitWidth:  label.implicitWidth
    implicitHeight: label.implicitHeight

    Label {
        id: label
        anchors.fill: parent
    }

    DropShadow {
        anchors.fill: label
        radius: 4
        samples: 8
        color: "#80000000"
        source: label
    }
}
