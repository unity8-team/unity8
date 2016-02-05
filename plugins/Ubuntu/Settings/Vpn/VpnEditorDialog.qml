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
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Components.Popups 1.3

Dialog {
    title: i18n.tr("Set up VPN")

    property var connection

    // Component.onCompleted: {
    //     // connection.updateSecrets()

    //     // var props = {"connection": connection}
    //     // switch (connection.type) {
    //     // // VpnConnection.OPENVPN:
    //     // case 0:
    //     //     basicPropertiesLoader.setSource("OpenvpnBasicProperties.qml", props)
    //     //     break
    //     // // VpnConnection.PPTP:
    //     // case 1:
    //     //     basicPropertiesLoader.setSource("PptpBasicProperties.qml", props)
    //     //     break
    //     // }
    // }

    Column {
        anchors { left: parent.left; right: parent.right }

        Row {
            Label {
                id: serverLabel
                text: i18n.tr("Server:")
                font.bold: true
                color: Theme.palette.selected.backgroundText
                elide: Text.ElideRight
            }

            Label {
                id: portLabel
                text: i18n.tr("Port:")
                font.bold: true
                color: Theme.palette.selected.backgroundText
                elide: Text.ElideRight
            }
        }

        Row {
            TextField {
                id: serverField
                objectName: "serverField"
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                Component.onCompleted: forceActiveFocus()
            }

            TextField {
                id: portField
                objectName: "portField"
                maximumLength: 5
                validator: portValidator
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                Component.onCompleted: forceActiveFocus()
            }
        }

        ListItem.ItemSelector {
            text: i18n.tr("Use this VPN for:")
            id: usageScopeField
            objectName: "usageScopeField"
            model: [i18n.tr("All network connections"),
                    i18n.tr("Its own network"),
                    i18n.tr("Specific routes")]

        }

        Row {
            id: typeRow

            Label {
                id: typeLabel
                text: i18n.tr("Type:")
                font.bold: true
                color: Theme.palette.selected.backgroundText
                elide: Text.ElideRight
            }

            ListItem.ItemSelector {
                id: typeField
                objectName: "typeField"
                enabled: model.length > 1
                model: i18n.tr("OpenVPN")
            }
        }
    }

    //     Loader {
    //         anchors { left: parent.left; right: parent.right }
    //         id: basicPropertiesLoader
    //     }
    // }

    RegExpValidator {
        id: portValidator
        regExp: /([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])/
    }
}
