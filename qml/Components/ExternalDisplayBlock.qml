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

Item {
    id: root
    property alias background: backgroundImage.source
    property real backgroundTopMargin

    CrossFadeImage {
        id: backgroundImage
        anchors.fill: parent
        anchors.topMargin: root.backgroundTopMargin
        fillMode: Image.PreserveAspectCrop
        // Limit how much memory we'll reserve for this image
        sourceSize.height: height
        sourceSize.width: width
    }

    UbuntuShape {
        anchors.fill: text
        anchors.margins: -units.gu(2)
        backgroundColor: UbuntuColors.orange
    }

    Label {
        id: text
        anchors.centerIn: parent
        width: parent.width / 2
        //visible: false
        text: i18n.tr("Your device is now connected to an external display.")
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        fontSize: "large"
        wrapMode: Text.Wrap
    }

    MouseArea {
        anchors.fill: parent
        enabled: parent.visible
        // eat all events
    }
}
