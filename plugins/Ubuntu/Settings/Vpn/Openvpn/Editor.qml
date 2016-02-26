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
            PropertyChanges { target: serverField; enabled: false }
            PropertyChanges { target: customPortToggle; enabled: false }
            PropertyChanges { target: portField; enabled: false }
            PropertyChanges { target: tcpToggle; enabled: false }
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

        },
        State {
            name: "succeeded"
            PropertyChanges {
                target: successIndicator
                running: true
            }
            PropertyChanges { target: serverField; enabled: false }
            PropertyChanges { target: customPortToggle; enabled: false }
            PropertyChanges { target: portField; enabled: false }
            PropertyChanges { target: tcpToggle; enabled: false }
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
        }
    ]

    // Return a list of pairs, first the server property name, then
    // the field value.
    function getChanges () {
        var fields = [
            ["remote",           serverField.text],
            ["portSet",          customPortToggle.checked],
            ["port",             parseInt(portField.text, 10) || 0],
            ["protoTcp",         tcpToggle.checked],
            ["cert",             certField.path],
            ["ca",               caField.path],
            ["key",              keyField.path],
            ["certPass",         certPassField.text],
            ["ta",               taField.path],
            ["taSet",            taSetToggle.checked],
            ["taDir",            parseInt(taDirSelector.selectedIndex, 10) || 0],
            ["remoteCertTlsSet", remoteCertSetToggle.checked],
            ["remoteCertTls",    parseInt(remoteCertTlsSelector.selectedIndex, 10) || 0],
            ["cipher",           parseInt(cipherSelector.selectedIndex, 10) || 0],
            ["compLzo",          compressionToggle.checked]
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
            text: i18n.tr("Server:")
            font.bold: true
            color: Theme.palette.selected.backgroundText
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        // Corresponds to the ":" element in the row of server:port textfields.
        Item {
            Layout.preferredWidth: units.gu(1)
            height: units.gu(1) // Value set for the sake of it being drawn.
        }

        Label {
            text: i18n.tr("Port:")
            font.bold: true
            color: Theme.palette.selected.backgroundText
            elide: Text.ElideRight
            Layout.preferredWidth: units.gu(10)
        }
    }

    RowLayout {
        anchors { left: parent.left; right: parent.right }

        TextField {
            id: serverField
            objectName: "vpnOpenvpnServerField"
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
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
        CheckBox {
            id: customPortToggle
            objectName: "vpnOpenvpnCustomPortToggle"
            checked: connection.portSet
        }

        Label {
            text: i18n.tr("Use custom gateway port:")
            Layout.fillWidth: true
        }
    }

    RegExpValidator {
        id: portValidator
        regExp: /([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])/
    }

    VpnTypeField {
        onTypeRequested: {
            typeChanged(connection, index);
        }
        Component.onCompleted: type = connection.type
    }

    RowLayout {
        Label {
            text: i18n.tr("Protocol:")
            font.bold: true
            color: Theme.palette.selected.backgroundText
            elide: Text.ElideRight
        }

        Label {
            id: tcpLabel
            text: i18n.tr("TCP")
        }

        CheckBox {
            id: tcpToggle
            objectName: "vpnOpenvpnTcpToggle"
            checked: connection.protoTcp
        }

        Label {
            text: i18n.tr("UDP")
        }

        CheckBox {
            id: udpToggle
            objectName: "vpnOpenvpnUdpToggle"
            checked: !tcpToggle.checked
            onTriggered: {
                tcpToggle.checked = !checked
                checked = Qt.binding(function () {
                    return !tcpToggle.checked
                });
            }
        }
    }

    Label {
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        text: i18n.tr("Client certificate:")
    }

    FileSelector {
        anchors { left: parent.left; right: parent.right }
        id: certField
        objectName: "vpnOpenvpnCertField"
        path: connection.cert
        chooseLabel: i18n.tr("Choose Certificate…")
    }

    Label {
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        text: i18n.tr("CA certificate:")
    }

    FileSelector {
        id: caField
        objectName: "vpnOpenvpnCaField"
        anchors { left: parent.left; right: parent.right }
        path: connection.ca
        chooseLabel: i18n.tr("Choose Certificate…")
    }

    Label {
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        text: i18n.tr("Private key:")
    }

    FileSelector {
        anchors { left: parent.left; right: parent.right }
        id: keyField
        objectName: "vpnOpenvpnKeyField"
        path: connection.key
        chooseLabel: i18n.tr("Choose Key…")
    }

    Label {
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        text: i18n.tr("Key password:")
    }

    TextField {
        anchors { left: parent.left; right: parent.right }
        id: certPassField
        objectName: "vpnOpenvpnCertPassField"
        echoMode: TextInput.Password
        text: connection.certPass
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
            text: i18n.tr("Use additional TLS authentication:")
            Layout.fillWidth: true
        }
    }

    Label {
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        text: i18n.tr("TLS key:")
        visible: taSetToggle.checked
    }

    FileSelector {
        anchors { left: parent.left; right: parent.right }
        id: taField
        objectName: "vpnOpenvpnTaField"
        path: connection.ta
        chooseLabel: i18n.tr("Choose Key…")
        visible: taSetToggle.checked
    }

    Label {
        text: i18n.tr("Key direction:")
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        visible: taSetToggle.checked
    }

    ListItems.ItemSelector {
        id: taDirSelector
        objectName: "vpnOpenvpnTaDirSelector"
        model: [
            i18n.tr("None"),
            i18n.tr("0"),
            i18n.tr("1"),
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
            text: i18n.tr("Verify peer certificate:")
            Layout.fillWidth: true
        }
    }

    Label {
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        text: i18n.tr("Peer certificate TLS type:")
        visible: remoteCertSetToggle.checked
    }

    ListItems.ItemSelector {
        id: remoteCertTlsSelector
        objectName: "vpnOpenvpnRemoteCertTlsSelector"
        model: [
            i18n.tr("Server"),
            i18n.tr("Client"),
        ]
        selectedIndex: connection.remoteCertTls
        visible: remoteCertSetToggle.checked
    }

    Label {
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        text: i18n.tr("Cipher:")
    }

    ListItems.ItemSelector {
        id: cipherSelector
        objectName: "vpnOpenvpnCipherSelector"
        model: [
            i18n.tr("Default"),
            i18n.tr("DES-CBC"),
            i18n.tr("RC2-CBC"),
            i18n.tr("DES-EDE-CBC"),
            i18n.tr("DES-EDE3-CBC"),
            i18n.tr("DESX-CBC"),
            i18n.tr("RC2-40-CBC"),
            i18n.tr("CAST5-CBC"),
            i18n.tr("AES-128-CBC"),
            i18n.tr("AES-192-CBC"),
            i18n.tr("AES-256-CBC"),
            i18n.tr("CAMELLIA-128-CBC"),
            i18n.tr("CAMELLIA-192-CBC"),
            i18n.tr("CAMELLIA-256-CBC"),
            i18n.tr("SEED-CBC"),
            i18n.tr("AES-128-CBC-HMAC-SHA1"),
            i18n.tr("AES-256-CBC-HMAC-SHA1"),
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
            text: i18n.tr("Compress data")
            Layout.fillWidth: true
        }
    }
}
