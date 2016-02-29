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

RowLayout {
    property alias type: vpnTypeSelector.selectedIndex

    signal typeRequested(int index)

    Label {
        text: i18n.tr("Type:")
        font.bold: true
        color: Theme.palette.selected.backgroundText
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
    }

    ListItems.ItemSelector {
        id: vpnTypeSelector
        objectName: "vpnTypeField"
        model: [
            i18n.tr("OpenVPN"),
            i18n.tr("Pptp")
        ]
        expanded: false
        onDelegateClicked: typeRequested(index)
        Layout.preferredWidth: units.gu(20)
        Layout.minimumHeight: currentlyExpanded ? itemHeight * model.length : itemHeight
    }
}
