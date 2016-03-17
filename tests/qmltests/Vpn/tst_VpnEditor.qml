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

    Component {
        id: vpnEditorPart
        Item {
            property bool changed: false
            property bool valid: false
            property var getChanges
        }
    }

    UbuntuTestCase {
        name: "VpnPptpEditor"
        when: windowShown

        function getLoader() {
            return findChild(vpnEditor, "editorLoader");
        }

        function init() {
            getLoader().sourceComponent = vpnEditorPart;
        }

        function test_editor_buttons_states_data() {
            return [
                { changed: false, valid: false, okayButtonEnabledTarget: false },
                { changed: true, valid: true, okayButtonEnabledTarget: true },
                { changed: true, valid: false, okayButtonEnabledTarget: false },
                { changed: false, valid: true, okayButtonEnabledTarget: false }
            ]
        }

        function test_editor_buttons_states(data) {
            var okayButton = findChild(vpnEditor, "vpnEditorOkayButton");
            var part = getLoader().item;
            part.changed = data.changed;
            part.valid = data.valid;
            compare(okayButton.enabled, data.okayButtonEnabledTarget);
        }

        function test_commit() {
            var item = getLoader().item;
            vpnEditor.connection = { gateway: "old" };

            // This function gets called by commit() and in it we
            // make sure the state has changed. We also return a change
            // to be committed.
            item.getChanges = function () {
                compare(item.state, "committing");
                return [["gateway", "new"]];
            }
            vpnEditor.commit();
            compare(item.state, "succeeded");
            compare(vpnEditor.connection["gateway"], "new");
        }
    }
}
