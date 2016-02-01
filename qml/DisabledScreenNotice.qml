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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Unity.Screens 0.1
import "Components"

Image {
    id: root

    UCUnits { id: unitsContainer; onGridUnitChanged: unitsChanged(); }
    property var units: unitsContainer // replaces units from UITK

    Rectangle { width: units.gu(10); height: width; color: 'red'; z: 10;
        Text { font.pixelSize: 30; text: units.gu(1); anchors.centerIn: parent }
        MouseArea { anchors.fill: parent; onClicked: parent.setScaleAndFormFactor(parent.scale + 0.2, Screens.FormFactorMonitor)}
    }

    WallpaperResolver {
        width: root.width
        id: wallpaperResolver
    }

    source: wallpaperResolver.background

    UbuntuShape {
        anchors.fill: text
        anchors.margins: -units.gu(2)
        backgroundColor: "black"
        opacity: 0.4
    }

    Label {
        id: text
        anchors.centerIn: parent
        width: parent.width / 2
        text: i18n.tr("Your device is now connected to an external display.")
        color: "white"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        fontSize: "x-large"
        wrapMode: Text.Wrap
    }
}
