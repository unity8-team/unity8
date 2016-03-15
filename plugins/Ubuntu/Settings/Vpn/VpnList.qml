/*
 * Copyright (C) 2016 Canonical Ltd.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Settings.Vpn 0.1

ListView {
    objectName: "vpnList"

    property var diag

    signal clickedConnection(var connection)

    anchors {
        left: parent.left
        right: parent.right
    }

    height: contentItem.height

    delegate: ListItem {
        objectName: "vpnListConnection" + index
        height: layout.height + divider.height
        onClicked: clickedConnection(connection)

        ListItemLayout {
            objectName: "vpnLayout"
            id: layout
            title.text: id

            Switch {
                SlotsLayout.position: SlotsLayout.Trailing;
                id: vpnSwitch
                objectName: "vpnSwitch"
                enabled: activatable
                Binding {target: vpnSwitch; property: "checked"; value: active}
                onTriggered: active = !active
            }
        }

        divider.visible: true

        trailingActions: ListItemActions {
           actions: [
               Action {
                   iconName: "delete"
                   text: i18n.dtr("ubuntu-settings-components", "Delete configuration")
                   onTriggered: connection.remove()
               }
           ]
       }
    }
}
