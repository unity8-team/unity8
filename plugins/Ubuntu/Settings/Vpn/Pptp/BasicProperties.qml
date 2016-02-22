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

    Label {
        id: serverLabel
        text: i18n.tr("Server:")
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        Layout.fillWidth: true
    }

    TextField {
        id: serverField
        objectName: "serverField"
        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
        Layout.fillWidth: true
        text: connection.gateway
        onTextChanged: {
            connection.gateway = text;
            connection.id = text;
        }
        Component.onCompleted: forceActiveFocus()
    }
}
