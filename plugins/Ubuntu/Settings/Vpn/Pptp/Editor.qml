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
    id: pptpEditor

    spacing: units.gu(1)

    property var connection

    Label {
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        text: i18n.tr("User:")
    }

    TextField {
        id: userFIeld
        objectName: "userField"
        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
        Layout.fillWidth: true
        text: connection.user
        onTextChanged: connection.user = text
    }

    Label {
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        text: i18n.tr("Password:")
    }

    TextField {
        id: passField
        anchors { left: parent.left; right: parent.right; }
        text: connection.password
        onTextChanged: connection.password = text
    }

    Label {
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        text: i18n.tr("NT Domain:")
    }

    TextField {
        id: domainField
        objectName: "domainField"
        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
        Layout.fillWidth: true
        text: connection.domain
        onTextChanged: connection.domain = text
    }

    RowLayout {
        CheckBox {
            id: bsdCompressionToggle
            checked: connection.bsdCompression
            onTriggered: connection.bsdCompression = checked
            activeFocusOnPress: false
        }

        Label {
            id: compressionLabel
            text: i18n.tr("Allow BSD data compression")
            Layout.fillWidth: true
        }
    }

    RowLayout {
        CheckBox {
            id: deflateCompressionToggle
            checked: connection.deflateCompression
            onTriggered: connection.deflateCompression = checked
            activeFocusOnPress: false
        }

        Label {
            text: i18n.tr("Allow Deflate data compression")
            Layout.fillWidth: true
        }
    }

    RowLayout {
        CheckBox {
            id: tcpCompressionToggle
            checked: connection.tcpHeaderCompression
            onTriggered: connection.tcpHeaderCompression = checked
            activeFocusOnPress: false
        }

        Label {
            text: i18n.tr("Use TCP Header compression")
            Layout.fillWidth: true
        }
    }

    Button {
        width: parent.width
        text: i18n.tr("OK")
        onClicked:  PopupUtils.close(editor)
    }
}
