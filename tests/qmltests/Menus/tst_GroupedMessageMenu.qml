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

import QtQuick 2.0
import QtTest 1.0
import Ubuntu.Test 0.1
import Ubuntu.Components 0.1
import Ubuntu.Settings.Menus 0.1
import "../utils.js" as UtilsJS

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

            GroupedMessageMenu {
                id: messageMenu
                removable: true

                title: "Group Message"
                count: "3"
            }
        }
    }

    SignalSpy {
        id: signalSpyActivateApp
        signalName: "appActivated"
        target: messageMenu
    }

    SignalSpy {
        id: signalSpyDismiss
        signalName: "dismissed"
        target: messageMenu
    }

    UbuntuTestCase {
        name: "GropedMessageMenu"
        when: windowShown

        function init() {
            signalSpyActivateApp.clear();
            signalSpyDismiss.clear();
        }

        function test_title_data() {
            return [
                { title: "title1" },
                { title: "title2" },
            ];
        }

        function test_title(data) {
            messageMenu.title = data.title;

            var title = UtilsJS.findChild(messageMenu, "title");
            verify(title !== undefined, "No title");
            compare(title.text, data.title, "Title does not match set title.");
        }

        function test_appIcon_data() {
            return [
                { appIcon: Qt.resolvedUrl("../../artwork/avatar.png") },
                { appIcon: Qt.resolvedUrl("../../artwork/rhythmbox.png") },
            ];
        }

        function test_appIcon(data) {
            messageMenu.appIcon = data.appIcon;
            var appIcon = UtilsJS.findChild(messageMenu, "appIcon");
            verify(appIcon !== undefined, "No app icon");
            compare(appIcon.source, data.appIcon, "App Icon does not match set icon.");
        }

        function test_count_data() {
            return [
                { count: "0" },
                { count: "5" },
            ];
        }

        function test_count(data) {
            messageMenu.count = data.count;

            var count = UtilsJS.findChild(messageMenu, "messageCount");
            verify(count !== undefined, "No count");
            compare(count.text, data.count, "Count does not match set count.");
        }

        function test_activate() {
            mouseClick(messageMenu, messageMenu.width / 2, messageMenu.height / 2, Qt.LeftButton, Qt.NoModifier, 0);
            compare(signalSpyActivateApp.count > 0, true, "activate app should have been triggered");
        }

        function test_dismiss() {
            mouseFlick(messageMenu, messageMenu.width / 2, messageMenu.height / 2, messageMenu.width, messageMenu.height / 2, true, true, units.gu(1), 10);
            tryCompare(function() { signalSpyDismiss.count > 0; }, true);
        }
    }
}
