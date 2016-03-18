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

    Flickable {
        id: flickable

        anchors.fill: parent
        contentWidth: column.width
        contentHeight: column.height

        Column {
            id: column

            width: flickable.width
            height: childrenRect.height

            VpnList {
                id: vpnList
                anchors { left: parent.left; right: parent.right }
                model: ListModel { id: vpnModel }
            }
        }
    }

    SignalSpy {
        id: connClickedSpy
        signalName: "clickedConnection"
        target: vpnList
    }

    UbuntuTestCase {
        name: "VpnList"
        when: windowShown

        function first() {
            return findChild(vpnList, "vpnListConnection" + 0);
        }

        function cleanup() {
            vpnModel.clear();
            connClickedSpy.clear();
        }

        function test_list_item_rendering_data() {
            return [
                {
                    tag: "inactive",
                    connection: {
                        id: 'inactive vpn',
                        activatable: true,
                        active: false
                    }
                },
                {
                    tag: "enabled",
                    connection: {
                        id: 'active vpn',
                        activatable: true,
                        active: true
                    }
                },
                {
                    tag: "disabled",
                    connection: {
                        id: 'bad vpn',
                        activatable: false,
                        active: false
                    }
                }
            ]
        }

        // Test the VPN connection as it appears in the VpnList
        function test_list_item_rendering(data) {
            var c = data.connection;
            vpnModel.append(c);

            // !! turns first() into a bool, which we compare with the
            // expected value.
            tryCompareFunction(function () { return !!first() }, true);

            var conn = first();
            var layout = findChild(conn, "vpnLayout");
            var trigger = findChild(conn, "vpnSwitch");
            compare(layout.title.text, c.id);
            compare(trigger.enabled, c.activatable);
            compare(trigger.checked, c.active);
        }

        function test_custom_click_event_data() {
            return [
                { tag: "openvpn", type: 0, id: "openvpn", active: false, activatable: false, connection: {}},
                { tag: "pptp", type: 1, id: "pptp", active: false, activatable: false, connection: {}}
            ]
        }

        // Make sure the custom click event is emitted for a connection
        function test_custom_click_event(data) {
            vpnModel.append(data);
            // Wait until first() returns the first vpn list element
            tryCompareFunction(function () { return typeof first() }, "object");

            var conn = first();
            mouseClick(conn, conn.width / 2, conn.height / 2);
            compare(connClickedSpy.count > 0, true, "connection click should have been triggered");
        }
    }
}
