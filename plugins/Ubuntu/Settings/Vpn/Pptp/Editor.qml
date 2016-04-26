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

    spacing: units.gu(2)

    property var connection
    property bool changed: getChanges().length > 0
    property bool valid: isValid()

    states: [
        State {
            name: "committing"
            PropertyChanges {
                target: okButtonIndicator
                running: true
            }
            PropertyChanges { target: gatewayField; enabled: false }
            PropertyChanges { target: routesField; enabled: false }
            PropertyChanges { target: userField; enabled: false }
            PropertyChanges { target: passwordField; enabled: false }
            PropertyChanges { target: domainField; enabled: false }
            PropertyChanges { target: requireMppeToggle; enabled: false }
            PropertyChanges { target: mppeTypeSelector; enabled: false }
            PropertyChanges { target: mppeStatefulToggle; enabled: false }
            PropertyChanges { target: allowPapToggle; enabled: false }
            PropertyChanges { target: allowChapToggle; enabled: false }
            PropertyChanges { target: allowMschapToggle; enabled: false }
            PropertyChanges { target: allowMschapv2Toggle; enabled: false }
            PropertyChanges { target: allowEapToggle; enabled: false }
            PropertyChanges { target: bsdCompressionToggle; enabled: false }
            PropertyChanges { target: deflateCompressionToggle; enabled: false }
            PropertyChanges { target: tcpHeaderCompressionToggle; enabled: false }
            PropertyChanges { target: sendPppEchoPacketsToggle; enabled: false }
            PropertyChanges { target: vpnEditorOkayButton; enabled: false }
        },
        State {
            name: "succeeded"
            extend: "committing"
            PropertyChanges {
                target: okButtonIndicator
                running: false
            }
            PropertyChanges {
                target: successIndicator
                running: true
            }
        }
    ]

    function isValid () {
        // XXX: Workaround for lp:1551258 where the backend refuses
        // blank passwords.
        return passwordField.text.length > 0;
    }

    // Return a list of pairs, first the server property name, then
    // the field value.
    function getChanges () {
        var fields = [
            ["gateway",              gatewayField.text],
            ["neverDefault",         routesField.neverDefault],
            ["user",                 userField.text],
            ["password",             passwordField.text],
            ["domain",               domainField.text],
            ["requireMppe",          requireMppeToggle.checked],
            ["mppeType",             mppeTypeSelector.selectedIndex],
            ["mppeStateful",         mppeStatefulToggle.checked],
            ["allowPap",             allowPapToggle.checked],
            ["allowChap",            allowChapToggle.checked],
            ["allowMschap",          allowMschapToggle.checked],
            ["allowMschapv2",        allowMschapv2Toggle.checked],
            ["allowEap",             allowEapToggle.checked],
            ["bsdCompression",       bsdCompressionToggle.checked],
            ["deflateCompression",   deflateCompressionToggle.checked],
            ["tcpHeaderCompression", tcpHeaderCompressionToggle.checked],
            ["sendPppEchoPackets",   sendPppEchoPacketsToggle.checked]
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
        text: i18n.dtr("ubuntu-settings-components", "Server:")
        font.bold: true
        color: theme.palette.normal.baseText
        elide: Text.ElideRight
    }

    TextField {
        anchors { left: parent.left; right: parent.right }
        id: gatewayField
        objectName: "vpnPptpGatewayField"
        inputMethodHints: Qt.ImhNoAutoUppercase
                          | Qt.ImhNoPredictiveText
                          | Qt.ImhUrlCharactersOnly
        text: connection.gateway
        Component.onCompleted: forceActiveFocus()
    }

    VpnRoutesField {
        objectName: "vpnPptpRoutesField"
        anchors { left: parent.left; right: parent.right }
        id: routesField
        neverDefault: connection.neverDefault
    }

    VpnTypeField {
        anchors { left: parent.left; right: parent.right }
        onTypeRequested: {
            editor.typeChanged(connection, index);
        }
        Component.onCompleted: type = connection.type
    }

    Label {
        font.bold: true
        color: theme.palette.normal.baseText
        elide: Text.ElideRight
        text: i18n.dtr("ubuntu-settings-components", "User:")
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
        color: theme.palette.normal.baseText
        elide: Text.ElideRight
        text: i18n.dtr("ubuntu-settings-components", "Password:")
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
        color: theme.palette.normal.baseText
        elide: Text.ElideRight
        text: i18n.dtr("ubuntu-settings-components", "NT Domain:")
    }

    TextField {
        id: domainField
        anchors { left: parent.left; right: parent.right }
        objectName: "vpnPptpDomainField"
        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
        text: connection.domain
    }

    Label {
        text: i18n.dtr("ubuntu-settings-components", "Authentication methods:")
        font.bold: true
        color: theme.palette.normal.baseText
        elide: Text.ElideRight
    }

    Column {
        anchors { left: parent.left; right: parent.right }
        spacing: units.gu(1)

        ListItems.ThinDivider {}

        RowLayout {
            visible: !requireMppeToggle.checked

            CheckBox {
                id: allowPapToggle
                objectName: "vpnPptpAllowPapToggle"
                checked: connection.allowPap
                activeFocusOnPress: false
            }

            Label {
                text: "PAP"
                Layout.fillWidth: true
            }
        }

        RowLayout {
            visible: !requireMppeToggle.checked

            CheckBox {
                id: allowChapToggle
                objectName: "vpnPptpAllowChapToggle"
                checked: connection.allowChap
                activeFocusOnPress: false
            }

            Label {
                text: "CHAP"
                Layout.fillWidth: true
            }
        }

        RowLayout {
            CheckBox {
                id: allowMschapToggle
                objectName: "vpnPptpAllowMschapToggle"
                checked: connection.allowMschap
                activeFocusOnPress: false
            }

            Label {
                text: "MSCHAP"
                Layout.fillWidth: true
            }
        }

        RowLayout {
            CheckBox {
                id: allowMschapv2Toggle
                objectName: "vpnPptpAllowMschapv2Toggle"
                checked: connection.allowMschapv2
                activeFocusOnPress: false
            }

            Label {
                text: "MSCHAPv2"
                Layout.fillWidth: true
            }
        }

        RowLayout {
            visible: !requireMppeToggle.checked

            CheckBox {
                id: allowEapToggle
                objectName: "vpnPptpAllowEapToggle"
                checked: connection.allowEap
                activeFocusOnPress: false
            }

            Label {
                text: "EAP"
                Layout.fillWidth: true
            }
        }

        ListItems.ThinDivider {}
    }

    RowLayout {
        CheckBox {
            id: requireMppeToggle
            objectName: "vpnPptpRequireMppeToggle"
            checked: connection.requireMppe
            activeFocusOnPress: false
        }

        Label {
            text: i18n.dtr("ubuntu-settings-components", "Use Point-to-Point encryption")
            Layout.fillWidth: true
        }
    }

    ListItems.ItemSelector {
        objectName: "vpnPptpMppeTypeSelector"
        id: mppeTypeSelector
        model: [
            i18n.dtr("ubuntu-settings-components", "All Available (Default)"),
            i18n.dtr("ubuntu-settings-components", "128-bit (most secure)"),
            i18n.dtr("ubuntu-settings-components", "40-bit (less secure)")
        ]
        selectedIndex: connection.mppeType
        enabled: requireMppeToggle.checked
    }

    RowLayout {
        CheckBox {
            id: mppeStatefulToggle
            objectName: "vpnPptpMppeStatefulToggle"
            checked: connection.mppeStateful
            activeFocusOnPress: false
            enabled: requireMppeToggle.checked
        }

        Label {
            text: i18n.dtr("ubuntu-settings-components", "Allow stateful encryption")
            Layout.fillWidth: true
        }
    }

    RowLayout {
        CheckBox {
            id: bsdCompressionToggle
            objectName: "vpnPptpBsdCompressionToggle"
            checked: connection.bsdCompression
            activeFocusOnPress: false
        }

        Label {
            text: i18n.dtr("ubuntu-settings-components", "Allow BSD data compression")
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
            text: i18n.dtr("ubuntu-settings-components", "Allow Deflate data compression")
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
            text: i18n.dtr("ubuntu-settings-components", "Use TCP Header compression")
            Layout.fillWidth: true
        }
    }

    RowLayout {
        CheckBox {
            id: sendPppEchoPacketsToggle
            objectName: "vpnPptpPppEchoPacketsToggle"
            checked: connection.sendPppEchoPackets
            activeFocusOnPress: false
        }

        Label {
            text: i18n.dtr("ubuntu-settings-components", "Send PPP echo packets")
            Layout.fillWidth: true
        }
    }
}
