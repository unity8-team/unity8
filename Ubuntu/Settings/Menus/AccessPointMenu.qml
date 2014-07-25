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
 * Authors:
 *      Renato Araujo Oliveira Filho <renato@canonical.com>
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem

ListItem.Empty {
    id: menu
    implicitHeight: units.gu(5.5)

    property bool active: false
    property bool secure: false
    property bool adHoc: false
    property int signalStrength: 0
    property alias text: label.text

    Icon {
        id: iconSignal
        objectName: "iconSignal"

        color: active ? Theme.palette.selected.foreground : Theme.palette.selected.backgroundText

        width: height
        height: Math.min(units.gu(3), parent.height - units.gu(1))
        anchors {
            left: parent.left
            leftMargin: menu.__contentsMargins
            verticalCenter: parent.verticalCenter
        }

        name: {
            var imageName = "nm-signal-100"

            if (adHoc) {
                imageName = "nm-adhoc";
            } else if (signalStrength <= 0) {
                imageName = "nm-signal-00";
            } else if (signalStrength <= 25) {
                imageName = "nm-signal-25";
            } else if (signalStrength <= 50) {
                imageName = "nm-signal-50";
            } else if (signalStrength <= 75) {
                imageName = "nm-signal-75";
            }
            return imageName;
        }
    }

    Label {
        id: label
        anchors {
            left: iconSignal.right
            leftMargin: units.gu(1)
            verticalCenter: parent.verticalCenter
            right: iconSecure.visible ? iconSecure.left : parent.right
            rightMargin: menu.__contentsMargins
        }
        elide: Text.ElideRight
        color: active ? Theme.palette.selected.foreground : Theme.palette.selected.backgroundText
    }

    Icon {
        id: iconSecure
        objectName: "iconSecure"
        visible: secure
        name: "network-secure"

        color: active ? Theme.palette.selected.foreground : Theme.palette.selected.backgroundText

        width: height
        height: Math.min(units.gu(3), parent.height - units.gu(1))
        anchors {
            right: parent.right
            rightMargin: menu.__contentsMargins
            verticalCenter: parent.verticalCenter
        }
    }
}
