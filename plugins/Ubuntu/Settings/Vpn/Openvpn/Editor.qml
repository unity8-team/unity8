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

Column {
    id: openvpnEditor
    spacing: units.gu(1)

    property var connection

    RowLayout {
        id: protocolRow

        Label {
            id: protocolLabel
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
            id: tcpSwitch
            checked: connection.protoTcp
            onTriggered: {
                connection.protoTcp = checked;
                checked = Qt.binding(function () {
                    return connection.protoTcp
                });
            }
        }

        Label {
            id: udpLabel
            text: i18n.tr("UDP")
        }

        CheckBox {
            id: udpSwitch
            checked: !connection.protoTcp
            onTriggered: {
                connection.protoTcp = !checked;
                checked = Qt.binding(function () {
                    return !connection.protoTcp
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
        id: certField
        anchors { left: parent.left; right: parent.right; }
        path: connection.cert
        onPathChanged: connection.cert = path
    }

    Label {
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        text: i18n.tr("CA certificate:")
    }

    FileSelector {
        id: caField
        anchors { left: parent.left; right: parent.right; }
        path: connection.ca
        onPathChanged: connection.ca = path
    }

    Label {
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        text: i18n.tr("Private key:")
    }

    FileSelector {
        id: keyField
        anchors { left: parent.left; right: parent.right; }
        path: connection.key
        onPathChanged: connection.key = path
    }

    Label {
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        text: i18n.tr("TLS key:")
    }

    RowLayout {
        CheckBox {
            id: taSetToggle
            checked: connection.taSet
            onTriggered: connection.taSet = checked
            activeFocusOnPress: false
        }

        Label {
            id: taSetLabel
            text: i18n.tr("Use additional TLS authentication:")
            Layout.fillWidth: true
        }
    }

    FileSelector {
        id: taField
        anchors { left: parent.left; right: parent.right; }
        path: connection.ta
        onPathChanged: connection.ta = path
        enabled: taSetToggle.checked
    }

    Label {
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        text: i18n.tr("Key password:")
        // Hidden due to lp:1546560.
        visible: false
    }

    TextField {
        id: certpassField
        anchors { left: parent.left; right: parent.right; }
        text: connection.certPass
        onTextChanged: connection.certPass = text
        // Hidden due to lp:1546560.
        visible: false
    }

    Label {
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        text: i18n.tr("Cipher:")
    }

    ListItems.ItemSelector {
        id: cipherField
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
        onDelegateClicked: connection.cipher = selectedIndex
    }

    RowLayout {
        CheckBox {
            id: compressionToggle
            checked: connection.compLzo
            onTriggered: connection.compLzo = checked
            activeFocusOnPress: false
        }

        Label {
            id: compressionLabel
            text: i18n.tr("Compress data")
            Layout.fillWidth: true
        }
    }

    Button {
        width: parent.width
        text: i18n.tr("OK")
        onClicked:  PopupUtils.close(editor)
    }
}
