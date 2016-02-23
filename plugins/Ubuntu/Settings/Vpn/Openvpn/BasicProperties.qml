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
    spacing: units.gu(1)

    property var connection

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
            objectName: "serverField"
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
            Layout.fillWidth: true
            text: connection.remote
            onTextChanged: {
                connection.remote = text;
                connection.id = text;
            }
            Component.onCompleted: forceActiveFocus()
        }

        Label {
            text: ":"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.preferredWidth: units.gu(1)
        }

        TextField {
            objectName: "portField"
            maximumLength: 5
            validator: portValidator
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
            text: connection.portSet ? connection.port : ""
            onTextChanged: connection.port = parseInt(text) || 0
            Layout.preferredWidth: units.gu(10)
            enabled: connection.portSet
        }
    }

    RowLayout {
        CheckBox {
            checked: connection.portSet
            onTriggered: connection.portSet = checked
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
}
