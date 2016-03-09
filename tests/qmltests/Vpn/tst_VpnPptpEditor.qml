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
import Ubuntu.Test 0.1
import Ubuntu.Settings.Vpn 0.1

Item {
    width: units.gu(42)
    height: units.gu(75)

    VpnEditor {
        anchors.fill: parent
        id: vpnEditor
    }

    UbuntuTestCase {
        name: "VpnPptpEditor"
        when: windowShown

        function getLoader() {
            return findChild(vpnEditor, "editorLoader");
        }

        function init () {
            waitForRendering(vpnEditor);
            vpnEditor.connection = {
                type:                 1, // pptp
                gateway:              "",
                neverDefault:         false,
                user:                 "",
                password:             "",
                domain:               "",
                requireMppe:          false,
                mppeType:             0,
                mppeStateful:         false,
                allowPap:             true,
                allowChap:            true,
                allowMschap:          true,
                allowMschapv2:        true,
                allowEap:             true,
                bsdCompression:       true,
                deflateCompression:   true,
                tcpHeaderCompression: true,
                sendPppEchoPackets:   false,
                updateSecrets: function () {}
            }
            vpnEditor.render();

            // Wait until we've loaded
            tryCompareFunction(function () { return typeof getLoader() }, "object");
            tryCompareFunction(function () { return getLoader().status }, Loader.Ready);
        }

        function test_fields() {
            var e                          = getLoader().item;
            var c                          = vpnEditor.connection;
            var gatewayField               = findChild(e, "vpnPptpGatewayField");
            var routesField                = findChild(e, "vpnPptpRoutesField");
            var userField                  = findChild(e, "vpnPptpUserField");
            var passwordField              = findChild(e, "vpnPptpPasswordField");
            var domainField                = findChild(e, "vpnPptpDomainField");
            var requireMppeToggle          = findChild(e, "vpnPptpRequireMppeToggle");
            var mppeTypeSelector           = findChild(e, "vpnPptpMppeTypeSelector");
            var mppeStatefulToggle         = findChild(e, "vpnPptpMppeStatefulToggle");
            var allowPapToggle             = findChild(e, "vpnPptpAllowPapToggle");
            var allowChapToggle            = findChild(e, "vpnPptpAllowChapToggle");
            var allowMschapToggle          = findChild(e, "vpnPptpAllowMschapToggle");
            var allowMschapv2Toggle        = findChild(e, "vpnPptpAllowMschapv2Toggle");
            var allowEapToggle             = findChild(e, "vpnPptpAllowEapToggle");
            var bsdCompressionToggle       = findChild(e, "vpnPptpBsdCompressionToggle");
            var deflateCompressionToggle   = findChild(e, "vpnPptpDeflateCompressionToggle");
            var tcpHeaderCompressionToggle = findChild(e, "vpnPptpHeaderCompressionToggle");
            var sendPppEchoPacketsToggle   = findChild(e, "vpnPptpPppEchoPacketsToggle");

            compare(gatewayField.text,                  c.gateway);
            compare(routesField.neverDefault,           c.neverDefault);
            compare(userField.text,                     c.user);
            compare(passwordField.text,                 c.password);
            compare(domainField.text,                   c.domain);
            compare(requireMppeToggle.checked,          c.requireMppe);
            compare(mppeTypeSelector.selectedIndex,     c.mppeType);
            compare(mppeStatefulToggle.checked,         c.mppeStateful);
            compare(allowPapToggle.checked,             c.allowPap);
            compare(allowChapToggle.checked,            c.allowChap);
            compare(allowMschapToggle.checked,          c.allowMschap);
            compare(allowMschapv2Toggle.checked,        c.allowMschapv2);
            compare(allowEapToggle.checked,             c.allowEap);
            compare(bsdCompressionToggle.checked,       c.bsdCompression);
            compare(deflateCompressionToggle.checked,   c.deflateCompression);
            compare(tcpHeaderCompressionToggle.checked, c.tcpHeaderCompression);
            compare(sendPppEchoPacketsToggle.checked,   c.sendPppEchoPackets);
        }

        function test_changes() {
            var e                    = getLoader().item;
            var c                    = vpnEditor.connection;
            var gatewayField         = findChild(e, "vpnPptpGatewayField");
            var userField            = findChild(e, "vpnPptpUserField");
            var passwordField        = findChild(e, "vpnPptpPasswordField");
            var bsdCompressionToggle = findChild(e, "vpnPptpBsdCompressionToggle");

            compare(e.getChanges(), []);

            // make some changes
            gatewayField.text = "new gateway";
            userField.text = "mark";
            passwordField.text = "1234";
            bsdCompressionToggle.checked = !c.bsdCompression;

            compare(e.getChanges(), [
                ["gateway", gatewayField.text],
                ["user", userField.text],
                ["password", passwordField.text],
                ["bsdCompression", bsdCompressionToggle.checked]
            ]);
        }

        function test_validity() {
            var e = getLoader().item;
            compare(getLoader().item.valid, false);

            // Make valid
            findChild(e, "vpnPptpPasswordField").text = "1234";

            compare(getLoader().item.valid, true);
        }
    }
}
