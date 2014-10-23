/*
 * Copyright 2014 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.3
import QtTest 1.0
import Ubuntu.Test 0.1
import Ubuntu.Settings.Components 0.1 as USC

Item {
    width: units.gu(40)
    height: units.gu(70)

    USC.SyncCheckBox {
        id: unidirectional
        bidirectional: false
    }

    USC.SyncCheckBox {
        id: bidirectional
        bidirectional: true
    }

    QtObject {
        id: backend
        property bool testChecked: false
    }

    QtObject {
        id: backend2
        property bool testChecked2: false
    }

    UbuntuTestCase {
        name: "Switch"
        when: windowShown

        function init() {
            backend.testChecked = false;
            unidirectional.checked = false;
            unidirectional.dataTarget = backend;
            unidirectional.dataProperty = "testChecked";

            bidirectional.checked = false;
            bidirectional.dataTarget = backend;
            bidirectional.dataProperty = "testChecked";
        }

        function test_backend_change() {
            backend.testChecked = true;
            compare(unidirectional.checked, true, "Switch should have been toggled");
            backend.testChecked = false;
            compare(unidirectional.checked, false, "Switch should have been toggled");
        }

        function test_break_binding_change() {
            unidirectional.checked = true;
            backend.testChecked = true;
            backend.testChecked = false;
            compare(unidirectional.checked, false, "Switch should have been toggled");
        }

        function test_unidirectional() {
            unidirectional.trigger();
            compare(backend.testChecked, !unidirectional.checked, "Backend should not have been toggled");
        }

        function test_bidirectional() {
            bidirectional.trigger();
            compare(backend.testChecked, bidirectional.checked, "Backend should have been toggled");

            bidirectional.trigger();
            compare(backend.testChecked, bidirectional.checked, "Backend should have been toggled");

            backend.testChecked = true;
            compare(bidirectional.checked, true, "Switch should have been toggled");

            backend.testChecked = false;
            compare(bidirectional.checked, false, "Switch should have been toggled");
        }

        function test_connect_to_another_object() {
            unidirectional.dataTarget = backend2;
            unidirectional.dataProperty = "testChecked2";

            backend2.testChecked2 = true;
            compare(unidirectional.checked, true, "Switch should have been toggled");
            backend2.testChecked2 = false;
            compare(unidirectional.checked, false, "Switch should have been toggled");
        }
    }
}
