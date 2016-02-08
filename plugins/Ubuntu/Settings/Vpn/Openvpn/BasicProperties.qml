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
import Ubuntu.Components.ListItems 1.3 as ListItems

Column {

    spacing: units.gu(2)

    Row {
        id: protocolRow

        Label {
            id: protocolLabel
            text: i18n.tr("Protocol:")
            font.bold: true
            color: Theme.palette.selected.backgroundText
            elide: Text.ElideRight
        }

        CheckBox {
            text: i18n.tr("TCP")
        }

        CheckBox {
            text: i18n.tr("UDP")
        }
    }

    FileSelector {
        anchors { left: parent.left; right: parent.right; }
        text: i18n.tr("Client certificate:")
        path: connection.cert
        onPathChanged: connection.cert = path
    }

    FileSelector {
        anchors { left: parent.left; right: parent.right; }
        text: i18n.tr("CA certificate:")
        path: connection.ca
        onPathChanged: connection.ca = path
    }

    FileSelector {
        anchors { left: parent.left; right: parent.right; }
        text: i18n.tr("Private key:")
        path: connection.key
        onPathChanged: connection.key = path
    }

    FileSelector {
        anchors { left: parent.left; right: parent.right; }
        text: i18n.tr("TLS key:")
        path: connection.ta
        onPathChanged: connection.ta = path
    }

    Label {
        text: i18n.tr("Key password:")
    }

    TextField {
        anchors { left: parent.left; right: parent.right; }
        text: connection.certPass
        onTextChanged: connection.certPass = text
    }
}
