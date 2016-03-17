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

    // In these tests, all CA certificates are going to be checked.
    UbuntuTestCase {
        name: "VpnPreviewDialogCertificateChecks"
        when: windowShown

        function cleanup() {
            PopupUtils.close(d);
        }

        function test_preview_dialog_data() {
            return [
                {
                    tag: "openvpn bad cert",
                    connection: {
                        id: 'openvpn bad cert',
                        remote: "ubuntu.com",
                        type: 0, // openvpn
                        ca: "bad.cert",
                        active: false,
                        neverDefault: false
                    },
                    targetObject: "vpnPreviewInvalidCert"
                }
            ]
        }

        function test_preview_dialog(data) {
            root.d = PopupUtils.open(diag, null, data);
            waitForRendering(root.d);
            var target = findChild(root.d, data.targetObject);
            var errorMsg = findChild(root.d, "vpnPreviewInvalidCertErrorMsg");
            verify(target, "found obj " + data.targetObject);
            compare(root.d.title, i18n.tr("VPN “%1”").arg(data.connection.remote || data.connection.gateway));
            compare(errorMsg.text, i18n.tr("Details: %1").arg(i18n.tr("The certificate was not found.")));
        }
    }
}
