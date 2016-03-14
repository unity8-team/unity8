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

Column {
    spacing: units.gu(2)
    objectName: "vpnPreviewNoCert"

    Label {
        wrapMode: Text.WordWrap
        anchors { left: parent.left; right: parent.right; }
        text: i18n.dtr("ubuntu-settings-components", "This VPN is not safe to use.")
    }

    Label {
        wrapMode: Text.WordWrap
        anchors { left: parent.left; right: parent.right; }
        text: i18n.dtr("ubuntu-settings-components", "It does not provide a certificate. The VPN provider could be impersonated.")
    }
}
