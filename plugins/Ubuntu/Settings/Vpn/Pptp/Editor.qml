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
import Ubuntu.Components.Popups 1.3
import ".."

Column {
    id: pptpEditor

    spacing: units.gu(1)

    property var connection
    property bool changed: getChanges().length > 0

    states: [
        State {
            name: "committing"
            PropertyChanges {
                target: okButtonIndicator
                running: true
            }
            PropertyChanges {
                target: secretUpdaterLoop
                running: true
            }
            PropertyChanges { target: gatewayField; enabled: false }
            PropertyChanges { target: userField; enabled: false }
            PropertyChanges { target: passwordField; enabled: false }
            PropertyChanges { target: domainField; enabled: false }
            PropertyChanges { target: bsdCompressionToggle; enabled: false }
            PropertyChanges { target: deflateCompressionToggle; enabled: false }
            PropertyChanges { target: tcpHeaderCompressionToggle; enabled: false }
        },
        State {
            name: "succeeded"
            PropertyChanges {
                target: successIndicator
                running: true
            }
            PropertyChanges { target: gatewayField; enabled: false }
            PropertyChanges { target: userField; enabled: false }
            PropertyChanges { target: passwordField; enabled: false }
            PropertyChanges { target: domainField; enabled: false }
            PropertyChanges { target: bsdCompressionToggle; enabled: false }
            PropertyChanges { target: deflateCompressionToggle; enabled: false }
            PropertyChanges { target: tcpHeaderCompressionToggle; enabled: false }

        }
    ]

    // Return a list of pairs, first the server property name, then
    // the field value.
    function getChanges () {
        var fields = [
            ["gateway",              gatewayField.text],
            ["user",                 userField.text],
            ["password",             passwordField.text],
            ["domain",               domainField.text],
            ["bsdCompression",       bsdCompressionToggle.checked],
            ["deflateCompression",   deflateCompressionToggle.checked],
            ["tcpHeaderCompression", tcpHeaderCompressionToggle.checked],
        ]
        var changedFields = [];

        // Push all fields that differs from the server to chanagedFields.
        for (var i = 0; i < fields.length; i++) {
            if (connection[fields[i][0]] !== fields[i][1]) {
                changedFields.push(fields[i]);
            }
        }

        return changedFields;
    }

    Label {
        text: i18n.tr("Server:")
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
    }

    TextField {
        id: gatewayField
        objectName: "vpnPptpGatewayField"
        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
        text: connection.gateway
        Component.onCompleted: forceActiveFocus()
    }

    VpnTypeField {
        onTypeRequested: {
            typeChanged(connection, index);
        }
        Component.onCompleted: type = connection.type
    }

    Label {
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        text: i18n.tr("User:")
    }

    TextField {
        id: userField
        anchors { left: parent.left; right: parent.right }
        objectName: "vpnPptpUserField"
        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
        text: connection.user
    }

    Label {
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        text: i18n.tr("Password:")
    }

    TextField {
        id: passwordField
        anchors { left: parent.left; right: parent.right }
        objectName: "vpnPptpPasswordField"
        echoMode: TextInput.Password
        text: connection.password
    }

    Label {
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        text: i18n.tr("NT Domain:")
    }

    TextField {
        id: domainField
        anchors { left: parent.left; right: parent.right }
        objectName: "vpnPptpDomainField"
        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
        text: connection.domain
    }

    RowLayout {
        CheckBox {
            id: bsdCompressionToggle
            objectName: "vpnPptpBsdCompressionToggle"
            checked: connection.bsdCompression
            activeFocusOnPress: false
        }

        Label {
            text: i18n.tr("Allow BSD data compression")
            Layout.fillWidth: true
        }
    }

    RowLayout {
        CheckBox {
            id: deflateCompressionToggle
            objectName: "vpnPptpDeflateCompressionToggle"
            checked: connection.deflateCompression
            activeFocusOnPress: false
        }

        Label {
            text: i18n.tr("Allow Deflate data compression")
            Layout.fillWidth: true
        }
    }

    RowLayout {
        CheckBox {
            id: tcpHeaderCompressionToggle
            objectName: "vpnPptpHeaderCompressionToggle"
            checked: connection.tcpHeaderCompression
            activeFocusOnPress: false
        }

        Label {
            text: i18n.tr("Use TCP Header compression")
            Layout.fillWidth: true
        }
    }
}
