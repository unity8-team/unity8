/*
 * Copyright 2014 Canonical Ltd.
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

            TransferMenu {
                id: transferMenu

                text: "Downloading Movie"
                progress: 0
                active: false
                iconSource: Qt.resolvedUrl("../../artwork/avatar.png")
            }
            TransferMenu {
                id: transferMenu2
                anchors.top: transferMenu.bottom

                text: "Syncing Data"
                progress: 0.6
                active: true
                iconSource: Qt.resolvedUrl("../../artwork/rhythmbox.png")
            }
        }
    }

    UbuntuTestCase {
        name: "TransferMenu"
        when: windowShown

        function init() {
            transferMenu.text = "";
            transferMenu.iconSource = "";
            transferMenu.progress = 0;
            transferMenu.active = false;
        }

        function test_iconSource_data() {
            return [ { icon: Qt.resolvedUrl("../../artwork/avatar.png") },
                     { icon: Qt.resolvedUrl("../../artwork/rhythmbox.png") }
            ];
        }

        function test_iconSource(data) {
            transferMenu.iconSource = data.icon;

            var icon = findChild(transferMenu, "icon");
            compare(icon.source, data.icon, "Icon does not match data");
        }

        function test_text_data() {
            return [ { text: "Text 1" },
                     { text: "Text 2" }
            ];
        }

        function test_text(data) {
            transferMenu.text = data.text;

            var text = findChild(transferMenu, "text");
            compare(text.text, data.text, "Text does not match data");
        }

        function test_stateText_data() {
            return [ { stateText: "State 1" },
                     { stateText: "State 2" }
            ];
        }

        function test_stateText(data) {
            transferMenu.stateText = data.stateText;

            var stateText = findChild(transferMenu, "stateText");
            compare(stateText.text, data.stateText, "State text does not match data");
        }

        function test_progress_data() {
            return [ { progress: 0.5 },
                     { progress: 1.0 }
            ];
        }

        function test_progress(data) {
            transferMenu.progress = data.progress;

            var progress = findChild(transferMenu, "progress");
            compare(progress.value, data.progress, "Progress does not match expected value");
        }

        function test_active() {
            var progress = findChild(transferMenu, "progress");
            var stateText = findChild(transferMenu, "stateText");

            transferMenu.active = true;
            compare(progress.visible, true, "Progress should be visible when active");
            compare(stateText.visible, true, "State should be visible when active");

            transferMenu.active = false;
            compare(progress.visible, false, "Progress should not be visible when inactive");
            compare(stateText.visible, false, "State should not be visible when inactive");
        }
    }
}
