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
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems

Column {
    id: routes
    spacing: units.gu(1)

    property alias neverDefault: ownNetworksToggle.checked
    property bool enabled: true

    Label {
        text: i18n.tr("Use this VPN for:")
        font.bold: true
        color: Theme.palette.normal.baseText
        elide: Text.ElideRight
    }

    Column {
        anchors { left: parent.left; right: parent.right }
        spacing: units.gu(1)

        ListItems.ThinDivider {}

        RowLayout {
            anchors { left: parent.left; right: parent.right }

            CheckBox {
                id: allNetworksToggle
                objectName: "vpnAllNetworksToggle"
                checked: !ownNetworksToggle.checked
                onTriggered: {
                    ownNetworksToggle.checked = !checked;
                    checked = Qt.binding(function () {
                        return !ownNetworksToggle.checked
                    });
                }
                enabled: routes.enabled
                activeFocusOnPress: false
            }

            Label {
                text: i18n.tr("All network connections")
                Layout.fillWidth: true
            }
        }

        RowLayout {
            anchors { left: parent.left; right: parent.right }

            CheckBox {
                id: ownNetworksToggle
                objectName: "vpnOwnNetworksToggle"
                enabled: routes.enabled
                activeFocusOnPress: false
            }

            Label {
                text: i18n.tr("Its own network")
                Layout.fillWidth: true
            }
        }

        ListItems.ThinDivider {}
    }
}
