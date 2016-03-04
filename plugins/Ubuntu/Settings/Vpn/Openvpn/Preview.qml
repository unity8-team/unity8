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
    property var connection
    property bool installed

    // The order of which source to load is determined by the order in which
    // they appear in the spec (starting with “This VPN is not safe to use.”)
    // and ending with “You’re using this VPN for specific services.”.
    // We do not currently deal with non-installed VPN connections, so we
    // assume the connection to be installed.
    function showPreview () {
        var c = connection;
        // “This VPN is not safe to use.”
        if (c.ca) {
            var err = UbuntuSettingsVpn.isCertificateValid(c.ca);
            switch (err) {
            case UbuntuSettingsVpn.CERT_NOT_FOUND:
            case UbuntuSettingsVpn.CERT_EMPTY:
            //case UbuntuSettingsVpn.CERT_SELFSIGNED:
            case UbuntuSettingsVpn.CERT_EXPIRED:
            case UbuntuSettingsVpn.CERT_BLACKLISTED:
                return contentLoader.setSource(
                   "../PreviewDialog/InvalidCert.qml",
                   { error: err }
                );
            default:
            case UbuntuSettingsVpn.CERT_VALID:
                break;
            }
        } else {
            return contentLoader.setSource("../PreviewDialog/NoCert.qml");
        }

        // “You’re using this VPN for all Internet traffic.”
        if (c.active && !c.neverDefault) {
            return contentLoader.setSource(
                "../PreviewDialog/AllTrafficWithoutDns.qml"
            );
        }

        // “This VPN is set up, but not in use now.”
        if (!c.active) {
            return contentLoader.setSource(
                "../PreviewDialog/SetUpUnused.qml"
            );
        }

        // “You’re using this VPN for specific services.”
        if (c.active && c.neverDefault) {
            return contentLoader.setSource(
                "../PreviewDialog/SomeTraffic.qml"
            );
        }
    }

    Component.onCompleted: showPreview()

    Loader {
        id: contentLoader
        anchors { left: parent.left; right: parent.right; }
    }
}
