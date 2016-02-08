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
    id: list

    property var diag

    function openConnection(connection) {
        diag = PopupUtils.open(vpnEditorDialog, list, {"connection": connection});
    }

    function previewConnection(connection) {
        diag = PopupUtils.open(vpnPreviewDialog, list, {"connection": connection});
    }

    anchors {
        left: parent.left
        right: parent.right
    }

    height: contentItem.height

    delegate: ListItem {
        height: layout.height + divider.height
        onClicked: previewConnection(connection)

        ListItemLayout {
            id: layout
            title.text: id
            Label {
                SlotsLayout.position: SlotsLayout.Trailing;
                text: active ? i18n.tr("On") : i18n.tr("Off")
            }
        }

        divider.visible: true

        trailingActions: ListItemActions {
           actions: [
               Action {
                   iconName: "delete"
                   text: i18n.tr("Delete configuration")
                   onTriggered: connection.remove()
               }
           ]
       }
    }

    // FIXME: Load this async
    Component {
        id: vpnPreviewDialog
        VpnPreviewDialog {
            onChangeClicked: {
                PopupUtils.close(diag);
                openConnection(connection);
            }
        }
    }

    // FIXME: Load this async
    Component {
        id: vpnEditorDialog
        VpnEditorDialog {}
    }
}
