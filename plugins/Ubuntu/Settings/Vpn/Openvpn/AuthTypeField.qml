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
    spacing: units.gu(1)

    property alias type: authTypeSelector.selectedIndex
    property bool enabled: true
    signal authTypeRequested(int index)

    Label {
        text: i18n.dtr("ubuntu-settings-components", "Authentication type:")
        enabled: parent.enabled
        font.bold: true
        color: theme.palette.normal.baseText
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignRight
    }

    ListItems.ItemSelector {
        id: authTypeSelector
        objectName: "vpnTypeField"
        enabled: parent.enabled
        model: [
            i18n.dtr("ubuntu-settings-components", "Certificates (TLS)"),
            i18n.dtr("ubuntu-settings-components", "Password"),
            i18n.dtr("ubuntu-settings-components", "Password with certificates (TLS)"),
            i18n.dtr("ubuntu-settings-components", "Static key")
        ]
        expanded: false
        onDelegateClicked: authTypeRequested(index)
    }
}
