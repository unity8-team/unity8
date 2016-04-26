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
    id: openVpnEditor

    spacing: units.gu(2)

    property var connection
    property bool changed: getChanges().length > 0
    property bool valid: true

    states: [
        State {
            name: "committing"
            PropertyChanges {
                target: okButtonIndicator
                running: true
            }
            PropertyChanges { target: serverField; enabled: false }
            PropertyChanges { target: customPortToggle; enabled: false }
            PropertyChanges { target: portField; enabled: false }
            PropertyChanges { target: routesField; enabled: false }
            PropertyChanges { target: tcpToggle; enabled: false }
            PropertyChanges { target: udpToggle; enabled: false }
            PropertyChanges { target: authTypeField; enabled: false }
            PropertyChanges { target: certField; enabled: false }
            PropertyChanges { target: caField; enabled: false }
            PropertyChanges { target: keyField; enabled: false }
            PropertyChanges { target: certPassField; enabled: false }
            PropertyChanges { target: taField; enabled: false }
            PropertyChanges { target: taSetToggle; enabled: false }
            PropertyChanges { target: taDirSelector; enabled: false }
            PropertyChanges { target: remoteCertSetToggle; enabled: false }
            PropertyChanges { target: remoteCertTlsSelector; enabled: false }
            PropertyChanges { target: cipherSelector; enabled: false }
            PropertyChanges { target: compressionToggle; enabled: false }
            PropertyChanges { target: vpnEditorOkayButton; enabled: false }
        },
        State {
            name: "succeeded"
            extend: "committing"
            PropertyChanges {
                target: successIndicator
                running: true
            }
            PropertyChanges {
                target: okButtonIndicator
                running: false
            }
        }
    ]

    // Return a list of pairs, first the server property name, then
    // the field value.
    function getChanges () {
        var fields = [
            ["remote",             serverField.text],
            ["portSet",            customPortToggle.checked],
            ["port",               parseInt(portField.text, 10) || 0],
            ["neverDefault",       routesField.neverDefault],
            ["protoTcp",           tcpToggle.checked],
            ["connectionType",     authTypeField.type],

            ["username",           usernameField.text],
            ["password",           passwordField.text],

            ["cert",               certField.path],
            ["ca",                 caField.path],
            ["key",                keyField.path],
            ["certPass",           certPassField.text],

            ["staticKey",          staticKeyField.path],
            ["staticKeyDirection", parseInt(staticKeyDirectionSelector.selectedIndex, 10) || 0],
            ["remoteIp",           remoteIpField.text],
            ["localIp",            localIpField.text],

            ["ta",                 taField.path],
            ["taSet",              taSetToggle.checked],
            ["taDir",              parseInt(taDirSelector.selectedIndex, 10) || 0],
            ["remoteCertTlsSet",   remoteCertSetToggle.checked],
            ["remoteCertTls",      parseInt(remoteCertTlsSelector.selectedIndex, 10) || 0],
            ["cipher",             parseInt(cipherSelector.selectedIndex, 10) || 0],
            ["compLzo",            compressionToggle.checked]
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

    RowLayout {
        anchors { left: parent.left; right: parent.right }

        Label {
            text: i18n.dtr("ubuntu-settings-components", "Server:")
            font.bold: true
            color: theme.palette.normal.baseText
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        // Corresponds to the ":" element in the row of server:port textfields.
        Item {
            Layout.preferredWidth: units.gu(1)
            height: units.gu(1) // Value set for the sake of it being drawn.
        }

        Label {
            text: i18n.dtr("ubuntu-settings-components", "Port:")
            font.bold: true
            color: theme.palette.normal.baseText
            elide: Text.ElideRight
            Layout.preferredWidth: units.gu(10)
        }
    }

    RowLayout {
        anchors { left: parent.left; right: parent.right }

        TextField {
            id: serverField
            objectName: "vpnOpenvpnServerField"
            inputMethodHints: Qt.ImhNoAutoUppercase
                              | Qt.ImhNoPredictiveText
                              | Qt.ImhUrlCharactersOnly
            Layout.fillWidth: true
            text: connection.remote
            Component.onCompleted: forceActiveFocus()
        }

        Label {
            text: ":"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.preferredWidth: units.gu(1)
        }

        TextField {
            id: portField
            objectName: "vpnOpenvpnPortField"
            maximumLength: 5
            validator: portValidator
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
            text: connection.port
            Layout.preferredWidth: units.gu(10)
            enabled: customPortToggle.checked
        }
    }

    RowLayout {
        anchors { left: parent.left; right: parent.right }
        CheckBox {
            id: customPortToggle
            objectName: "vpnOpenvpnCustomPortToggle"
            checked: connection.portSet
        }

        Label {
            text: i18n.dtr("ubuntu-settings-components", "Use custom gateway port")
            Layout.fillWidth: true
        }
    }

    VpnRoutesField {
        id: routesField
        objectName: "vpnOpenvpnRoutesField"
        anchors { left: parent.left; right: parent.right }
        neverDefault: connection.neverDefault
    }

    RegExpValidator {
        id: portValidator
        regExp: /([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])/
    }

    VpnTypeField {
        anchors { left: parent.left; right: parent.right }
        // type does not notify, so we avoid binding to suppress warnings
        Component.onCompleted: type = connection.type
        onTypeRequested: {
            editor.typeChanged(connection, index);
        }
    }

    RowLayout {
        Label {
            text: i18n.dtr("ubuntu-settings-components", "Protocol:")
            font.bold: true
            color: theme.palette.normal.baseText
            elide: Text.ElideRight
        }

        Label {
            id: tcpLabel
            text: "TCP"
        }

        CheckBox {
            id: tcpToggle
            objectName: "vpnOpenvpnTcpToggle"
            checked: connection.protoTcp
        }

        Label {
            text: "UDP"
        }

        CheckBox {
            id: udpToggle
            objectName: "vpnOpenvpnUdpToggle"
            checked: !tcpToggle.checked
            onTriggered: {
                tcpToggle.checked = !checked;
                checked = Qt.binding(function () {
                    return !tcpToggle.checked
                });
            }
        }
    }

    AuthTypeField {
        id: authTypeField
        objectName: "vpnOpenvpnAuthTypeField"
        anchors { left: parent.left; right: parent.right }
        states: [
            State {
                name: "tls"
                PropertyChanges { target: authTls; visible: true }
            },
            State {
                name: "password"
                PropertyChanges { target: authPassword; visible: true }
            },
            State {
                name: "passwordtls"
                PropertyChanges { target: authPassword; visible: true }
                PropertyChanges { target: authTls; visible: true }
            },
            State {
                name: "static"
                PropertyChanges { target: authStatic; visible: true }
                PropertyChanges { target: caLabel; visible: false }
                PropertyChanges { target: caField; visible: false }
            }
        ]
        type: connection.connectionType
        onAuthTypeRequested: {
            switch (index) {
            case 0: // OpenvpnConnection.TLS
                state = "tls";
                break
            case 1: // OpenvpnConnection.PASSWORD
                state = "password";
                break
            case 2: // OpenvpnConnection.PASSWORD_TLS
                state = "passwordtls";
                break
            case 3: // OpenvpnConnection.STATIC_KEY
                state = "static";
                break
            }
        }
        Component.onCompleted: authTypeRequested(connection.connectionType)
    }

    Column {
        id: authPassword
        anchors { left: parent.left; right: parent.right }
        visible: false
        spacing: openVpnEditor.spacing

        Label {
            font.bold: true
            color: theme.palette.normal.baseText
            elide: Text.ElideRight
            text: i18n.dtr("ubuntu-settings-components", "Username:")
        }

        TextField {
            id: usernameField
            anchors { left: parent.left; right: parent.right }
            objectName: "vpnOpenvpnUsernameField"
            text: connection.username
            inputMethodHints: Qt.ImhNoPredictiveText
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
            objectName: "vpnOpenvpnPasswordField"
            text: connection.password
            echoMode: TextInput.PasswordEchoOnEdit
        }
    }

    Column {
        id: authTls
        anchors { left: parent.left; right: parent.right }
        visible: false
        spacing: openVpnEditor.spacing

        Label {
            font.bold: true
            color: theme.palette.normal.baseText
            elide: Text.ElideRight
            text: i18n.dtr("ubuntu-settings-components", "Client certificate:")
        }

        FileSelector {
            anchors { left: parent.left; right: parent.right }
            id: certField
            objectName: "vpnOpenvpnCertField"
            path: connection.cert
            chooseLabel: i18n.dtr("ubuntu-settings-components", "Choose Certificate…")
        }

        Label {
            font.bold: true
            color: theme.palette.normal.baseText
            elide: Text.ElideRight
            text: i18n.dtr("ubuntu-settings-components", "Private key:")
        }

        FileSelector {
            anchors { left: parent.left; right: parent.right }
            id: keyField
            objectName: "vpnOpenvpnKeyField"
            path: connection.key
            chooseLabel: i18n.dtr("ubuntu-settings-components", "Choose Key…")
        }

        Label {
            font.bold: true
            color: theme.palette.normal.baseText
            elide: Text.ElideRight
            text: i18n.dtr("ubuntu-settings-components", "Key password:")
        }

        TextField {
            anchors { left: parent.left; right: parent.right }
            id: certPassField
            objectName: "vpnOpenvpnCertPassField"
            echoMode: TextInput.Password
            text: connection.certPass
        }
    }

    Label {
        id: caLabel
        font.bold: true
        color: theme.palette.normal.baseText
        elide: Text.ElideRight
        text: i18n.dtr("ubuntu-settings-components", "CA certificate:")
    }

    FileSelector {
        id: caField
        objectName: "vpnOpenvpnCaField"
        anchors { left: parent.left; right: parent.right }
        path: connection.ca
        chooseLabel: i18n.dtr("ubuntu-settings-components", "Choose Certificate…")
    }

    Column {
        id: authStatic
        anchors { left: parent.left; right: parent.right }
        visible: false
        spacing: openVpnEditor.spacing

        Label {
            font.bold: true
            color: theme.palette.normal.baseText
            elide: Text.ElideRight
            text: i18n.dtr("ubuntu-settings-components", "Static key:")
        }

        FileSelector {
            id: staticKeyField
            anchors { left: parent.left; right: parent.right }
            objectName: "vpnOpenvpnStaticKeyField"
            path: connection.staticKey
            chooseLabel: i18n.dtr("ubuntu-settings-components", "Choose Key…")
        }

        Label {
            text: i18n.dtr("ubuntu-settings-components", "Key direction:")
            font.bold: true
            color: theme.palette.normal.baseText
            elide: Text.ElideRight
        }

        ListItems.ItemSelector {
            id: staticKeyDirectionSelector
            objectName: "vpnOpenvpnStaticKeyDirectionSelector"
            model: [
                i18n.dtr("ubuntu-settings-components", "None"),
                0,
                1,
            ]
            selectedIndex: connection.staticKeyDirection
        }

        Label {
            text: i18n.dtr("ubuntu-settings-components", "Remote IP:")
            font.bold: true
            color: theme.palette.normal.baseText
            elide: Text.ElideRight
        }

        TextField {
            id: remoteIpField
            anchors { left: parent.left; right: parent.right }
            text: connection.remoteIp
            objectName: "vpnOpenvpnRemoteIpField"
            inputMethodHints: Qt.ImhNoPredictiveText
        }

        Label {
            text: i18n.dtr("ubuntu-settings-components", "Local IP:")
            font.bold: true
            color: theme.palette.normal.baseText
            elide: Text.ElideRight
        }

        TextField {
            id: localIpField
            anchors { left: parent.left; right: parent.right }
            text: connection.localIp
            objectName: "vpnOpenvpnLocalIpField"
            inputMethodHints: Qt.ImhNoPredictiveText
        }
    }

    RowLayout {
        CheckBox {
            id: taSetToggle
            objectName: "vpnOpenvpnTaSetToggle"
            checked: connection.taSet
            onTriggered: connection.taSet = checked
            activeFocusOnPress: false
        }

        Label {
            text: i18n.dtr("ubuntu-settings-components", "Use additional TLS authentication:")
            Layout.fillWidth: true
        }
    }

    Label {
        font.bold: true
        color: theme.palette.normal.baseText
        elide: Text.ElideRight
        text: i18n.dtr("ubuntu-settings-components", "TLS key:")
        visible: taSetToggle.checked
    }

    FileSelector {
        anchors { left: parent.left; right: parent.right }
        id: taField
        objectName: "vpnOpenvpnTaField"
        path: connection.ta
        chooseLabel: i18n.dtr("ubuntu-settings-components", "Choose Key…")
        visible: taSetToggle.checked
    }

    Label {
        text: i18n.dtr("ubuntu-settings-components", "Key direction:")
        font.bold: true
        color: theme.palette.normal.baseText
        elide: Text.ElideRight
        visible: taSetToggle.checked
    }

    ListItems.ItemSelector {
        id: taDirSelector
        objectName: "vpnOpenvpnTaDirSelector"
        model: [
            i18n.dtr("ubuntu-settings-components", "None"),
            0,
            1,
        ]
        selectedIndex: connection.taDir
        visible: taSetToggle.checked
    }

    RowLayout {
        CheckBox {
            id: remoteCertSetToggle
            objectName: "vpnOpenvpnRemoteCertSetToggle"
            checked: connection.remoteCertTlsSet
            activeFocusOnPress: false
        }

        Label {
            text: i18n.dtr("ubuntu-settings-components", "Verify peer certificate:")
            Layout.fillWidth: true
        }
    }

    Label {
        font.bold: true
        color: theme.palette.normal.baseText
        elide: Text.ElideRight
        text: i18n.dtr("ubuntu-settings-components", "Peer certificate TLS type:")
        visible: remoteCertSetToggle.checked
    }

    ListItems.ItemSelector {
        id: remoteCertTlsSelector
        objectName: "vpnOpenvpnRemoteCertTlsSelector"
        model: [
            i18n.dtr("ubuntu-settings-components", "Server"),
            i18n.dtr("ubuntu-settings-components", "Client"),
        ]
        selectedIndex: connection.remoteCertTls
        visible: remoteCertSetToggle.checked
    }

    Label {
        font.bold: true
        color: theme.palette.normal.baseText
        elide: Text.ElideRight
        text: i18n.dtr("ubuntu-settings-components", "Cipher:")
    }

    ListItems.ItemSelector {
        id: cipherSelector
        objectName: "vpnOpenvpnCipherSelector"
        model: [
            i18n.dtr("ubuntu-settings-components", "Default"),
            "DES-CBC",
            "RC2-CBC",
            "DES-EDE-CBC",
            "DES-EDE3-CBC",
            "DESX-CBC",
            "RC2-40-CBC",
            "CAST5-CBC",
            "AES-128-CBC",
            "AES-192-CBC",
            "AES-256-CBC",
            "CAMELLIA-128-CBC",
            "CAMELLIA-192-CBC",
            "CAMELLIA-256-CBC",
            "SEED-CBC",
            "AES-128-CBC-HMAC-SHA1",
            "AES-256-CBC-HMAC-SHA1",
        ]
        selectedIndex: connection.cipher
    }

    RowLayout {
        CheckBox {
            id: compressionToggle
            objectName: "vpnOpenvpnCompressionToggle"
            checked: connection.compLzo
            activeFocusOnPress: false
        }

        Label {
            text: i18n.dtr("ubuntu-settings-components", "Compress data")
            Layout.fillWidth: true
        }
    }
}
