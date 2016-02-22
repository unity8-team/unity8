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

    Component.onCompleted: {
        var defaultSource;

        if (installed) {
            // The API does not support routes yet (lp:1546573), so we treat
            // any active VPN as if it is routing all traffic.
             defaultSource = connection.active ?
                             "../PreviewDialog/AllTrafficWithoutDns.qml"
                             : "../PreviewDialog/SetUpUnused.qml";
        } else {
             defaultSource = "../PreviewDialog/NotInstalledWithoutRoutes.qml";
        }

        // Note: the server certificate check sets a loder source and returns.
        if (connection.ca) {
            var err = UbuntuSettingsVpn.isCertificateValid(connection.ca);
            switch (err) {
            case UbuntuSettingsVpn.CERT_NOT_FOUND:
            case UbuntuSettingsVpn.CERT_EMPTY:
            case UbuntuSettingsVpn.CERT_SELFSIGNED:
            case UbuntuSettingsVpn.CERT_EXPIRED:
            case UbuntuSettingsVpn.CERT_BLACKLISTED:
                contentLoader.setSource("../PreviewDialog/InvalidCert.qml", {
                    error: err
                });
                return;
            default:
            case UbuntuSettingsVpn.CERT_VALID:
                break;
            }
        } else {
            contentLoader.setSource("../PreviewDialog/NoCert.qml");
            return;
        }

        contentLoader.setSource(defaultSource);
    }

    Loader {
        id: contentLoader
        anchors { left: parent.left; right: parent.right; }
    }
}
