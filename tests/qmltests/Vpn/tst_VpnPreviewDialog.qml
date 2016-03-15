/*
 * Copyright 2016 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by Jonas G. Drange <jonas.drange@canonical.com>
 */

import QtQuick 2.4
import QtTest 1.0
import Ubuntu.Components.Popups 1.3
import Ubuntu.Test 0.1
import Ubuntu.Settings.Vpn 0.1

Item {
    width: units.gu(42)
    height: units.gu(75)

    id: root
    property var d

    Component {
        id: diag
        VpnPreviewDialog {

        }
    }

    // In these tests, all CA certificates are going to be okay due to
    // NO_SSL_CERTIFICATE_CHECK env variable being set to 1.
    UbuntuTestCase {
        name: "VpnPreviewDialog"
        when: windowShown

        function cleanup() {
            PopupUtils.close(d);
        }

        function test_preview_dialog_data() {
            return [
                {
                    tag: "openvpn upunused",
                    connection: {
                        id: 'openvpn unused',
                        remote: "ubuntu.com",
                        type: 0, // openvpn
                        ca: "okay",
                        active: false,
                        neverDefault: false
                    },
                    targetObject: "vpnPreviewSetUpUnused"
                },
                {
                    tag: "openvpn all",
                    connection: {
                        id: 'openvpn all',
                        remote: "ubuntu.com",
                        type: 0, // openvpn
                        ca: "okay",
                        active: true,
                        neverDefault: false
                    },
                    targetObject: "vpnPreviewAllTrafficWithoutDns"
                },
                {
                    tag: "openvpn some",
                    connection: {
                        id: 'openvpn some',
                        remote: "ubuntu.com",
                        type: 0, // openvpn
                        ca: "okay",
                        active: true,
                        neverDefault: false
                    },
                    targetObject: "vpnPreviewAllTrafficWithoutDns"
                },
                {
                    tag: "openvpn no ca",
                    connection: {
                        id: 'openvpn no ca',
                        remote: "ubuntu.com",
                        type: 0, // openvpn
                        active: true,
                        neverDefault: false
                    },
                    targetObject: "vpnPreviewNoCert"
                },
                {
                    tag: "pptp all",
                    connection: {
                        id: 'pptp all',
                        gateway: "ubuntu.com",
                        type: 1, // pptp
                        active: true,
                        neverDefault: false
                    },
                    targetObject: "vpnPreviewAllTrafficWithoutDns"
                },
                {
                    tag: "pptp unused",
                    connection: {
                        id: 'pptp unused',
                        gateway: "ubuntu.com",
                        type: 1, // pptp
                        active: false,
                        neverDefault: false
                    },
                    targetObject: "vpnPreviewSetUpUnused"
                },
                {
                    tag: "pptp some",
                    connection: {
                        id: 'pptp some',
                        gateway: "ubuntu.com",
                        type: 1, // pptp
                        active: true,
                        neverDefault: true
                    },
                    targetObject: "vpnPreviewSomeTraffic"
                }
            ]
        }

        function test_preview_dialog(data) {
            root.d = PopupUtils.open(diag, null, data);
            waitForRendering(root.d);
            var target = findChild(root.d, data.targetObject);
            verify(target, "found obj " + data.targetObject);
            compare(root.d.title, i18n.tr("VPN “%1”").arg(data.connection.remote || data.connection.gateway));
        }
    }
}
