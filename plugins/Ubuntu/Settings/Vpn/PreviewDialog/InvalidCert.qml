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
import Ubuntu.Settings.Vpn 0.1

Column {

    property var error;

    spacing: units.gu(2)

    Label {
        wrapMode: Text.WordWrap
        anchors { left: parent.left; right: parent.right; }
        text: i18n.tr("This VPN is not safe to use.")
    }

    Label {
        wrapMode: Text.WordWrap
        anchors { left: parent.left; right: parent.right; }
        text: i18n.tr("The server certificate is not valid. The VPN provider may be being impersonated.")
    }

    Label {
        wrapMode: Text.WordWrap
        anchors { left: parent.left; right: parent.right; }
        visible: error
        text: {
            // TRANSLATORS: %1 is a reason for why a VPN certificate was invalid.
            var detailsLabel = i18n.tr("Details: %1");
            var errorMsg;

            switch(error) {
            case UbuntuSettingsVpn.CERT_NOT_FOUND:
                errorMsg = i18n.tr("The certificate was not found.");
                break;
            case UbuntuSettingsVpn.CERT_EMPTY:
                errorMsg = i18n.tr("The certificate is empty.");
                break;
            case UbuntuSettingsVpn.CERT_SELFSIGNED:
                errorMsg = i18n.tr("The certificate is self signed.");
                break;
            case UbuntuSettingsVpn.CERT_EXPIRED:
                errorMsg = i18n.tr("The certificate has expired.");
                break;
            case UbuntuSettingsVpn.CERT_BLACKLISTED:
                errorMsg = i18n.tr("The certificate is blacklisted.");
                break;
            }
            return errorMsg ? detailsLabel.arg(errorMsg) : "";
        }
    }
}
