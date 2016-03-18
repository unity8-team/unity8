/*
 * Copyright 2013 Canonical Ltd.
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
 * Authored by Nick Dedekind <nick.dedekind@canonical.com>
 */

import QtQuick 2.4
import QtTest 1.0
import Ubuntu.Test 0.1
import Ubuntu.Settings.Menus 0.1

Item {
    width: units.gu(42)
    height: units.gu(75)

    Flickable {
        id: flickable

        anchors.fill: parent
        contentWidth: column.width
        contentHeight: column.height

        Item {
            id: column

            width: flickable.width
            height: childrenRect.height

            AccessPointMenu {
                id: accessPoint
                text: "AccessPointMenu"
            }
            AccessPointMenu {
                id: accessPoint2
                anchors.top: accessPoint.bottom

                active: true
                secure: true
                adHoc: true
                signalStrength: 50
                text: "AccessPointMenu 2"
            }
        }
    }

    SignalSpy {
        id: signalSpyTriggered
        signalName: "triggered"
        target: accessPoint
    }

    UbuntuTestCase {
        name: "AccessPointMenu"
        when: windowShown

        function init() {
            accessPoint.active = false;
            accessPoint.secure = false;
            accessPoint.adHoc = false;
            accessPoint.signalStrength = 0;
            signalSpyTriggered.clear();
        }

        function test_activate() {
            mouseClick(accessPoint, accessPoint.width / 2, accessPoint.height / 2);
            compare(signalSpyTriggered.count > 0, true, "activate signal should have been triggered");
        }

        function test_signalIcon_data() {
            return [
                {tag: '-10', signal:-10, adHoc: false, icon: "nm-signal-00"},
                {tag: '-10:adhoc', signal:-10, adHoc: true, icon: "nm-adhoc"},

                {tag: '0', signal:0, adHoc: false, icon: "nm-signal-00"},
                {tag: '0:adhoc', signal:0, adHoc: true, icon: "nm-adhoc"},

                {tag: '25', signal:25, adHoc: false, icon: "nm-signal-25"},
                {tag: '25:adhoc', signal:25, adHoc: true, icon: "nm-adhoc"},

                {tag: '50', signal:50, adHoc: false, icon: "nm-signal-50"},
                {tag: '50:adhoc', signal:50, adHoc: true, icon: "nm-adhoc"},

                {tag: '75', signal:75, adHoc: false, icon: "nm-signal-75"},
                {tag: '75:adhoc', signal:75, adHoc: true, icon: "nm-adhoc"},

                {tag: '100', signal:100, adHoc: false, icon: "nm-signal-100"},
                {tag: '100:adhoc', signal:100, adHoc: true, icon: "nm-adhoc"},

                {tag: '200', signal:200, adHoc: false, icon: "nm-signal-100"},
                {tag: '200:adhoc', signal:200, adHoc: true, icon: "nm-adhoc"},
            ];
        }

        function test_signalIcon(data) {
            accessPoint.signalStrength = data.signal;
            accessPoint.adHoc = data.adHoc;

            var icon = findChild(accessPoint, "iconSignal");
            verify(icon !== undefined);

            compare(icon.name, data.icon, "Incorret icon for strength");
        }

        function test_secure(data) {
            var icon = findChild(accessPoint, "iconSecure");
            verify(icon !== undefined);

            accessPoint.secure = true;
            compare(icon.visible, true, "Secure icon should be visible when access point is secure");

            accessPoint.secure = false;
            compare(icon.visible, false, "Secure icon should not be visible when access point is not secure");
        }
    }
}
