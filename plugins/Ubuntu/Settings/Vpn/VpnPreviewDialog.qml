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
import Ubuntu.Components.Popups 1.3

Dialog {
    objectName: "vpnPreviewDialog"
    id: preview

    // A connection we assume to be installed.
    property var connection

    // A configuration we assume is not installed.
    // A configuration is expected to behave the same way
    // as a connection.
    property var configuration

    function getConnection () {
        return connection ? connection : configuration;
    }

    function isInstalled () {
        return !!connection;
    }

    signal changeClicked(var connection)
    signal installClicked(var configuration)

    Component.onCompleted: {
        var source;
        var conn = getConnection();

        switch (conn.type) {
            case 0: // Openvpn
                source = "Openvpn/Preview.qml";
                // TRANSLATORS: %1 is the hostname of a VPN connection
                if (conn.remote) title = i18n.tr("VPN “%1”").arg(conn.remote);
                break;
            case 1: // PPTP
                source = "Pptp/Preview.qml";
                // TRANSLATORS: %1 is the hostname of a VPN connection
                if (conn.gateway) title = i18n.tr("VPN “%1”").arg(conn.gateway);
                break;
            default: // Unknown
                source = "";
                break;
        }

        contentLoader.setSource(source, {
            connection: getConnection(),
            installed: isInstalled()
        });
        title = i18n.tr("VPN");
    }

    Loader {
        id: contentLoader
        anchors { left: parent.left; right: parent.right; }
    }

    RowLayout {
        spacing: units.gu(2)

        Button {
            objectName: "vpnPreviewRemoveButton"
            Layout.fillWidth: true
            visible: !!connection
            text: i18n.tr("Remove")
            color: UbuntuColors.red
            onClicked: {
                connection.remove();
                PopupUtils.close(preview);
            }
        }

        Button {
            objectName: "vpnPreviewChangeButton"
            Layout.fillWidth: true
            visible: !!connection
            text: i18n.tr("Change")
            onClicked: changeClicked(connection)
        }

        Button {
            objectName: "vpnPreviewCancelButton"
            Layout.fillWidth: true
            visible: !!configuration
            text: i18n.tr("Cancel")
            onClicked: PopupUtils.close(preview)
        }

        Button {
            objectName: "vpnPreviewInstallButton"
            Layout.fillWidth: true
            visible: !!configuration
            text: i18n.tr("Install")
            onClicked: installClicked(configuration)
        }
    }
}
