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

            GroupedMessageMenu {
                id: messageMenu
                removable: false

                text: "Group Message 1"
                count: "3"
            }

            GroupedMessageMenu {
                id: messageMenu2
                removable: true
                anchors.top: messageMenu.bottom

                text: "Group Message 2"
                count: "5"
            }
        }
    }

    SignalSpy {
        id: signalSpyTriggered
        signalName: "triggered"
        target: messageMenu
    }

    SignalSpy {
        id: signalSpyDismiss
        signalName: "dismissed"
        target: messageMenu2
    }

    TestCase {
        name: "GropedMessageMenu"
        when: windowShown

        function init() {
            signalSpyTriggered.clear();
            signalSpyDismiss.clear();
        }

        function test_triggered() {
            mouseClick(messageMenu, messageMenu.width / 2, messageMenu.height / 2);
            compare(signalSpyTriggered.count > 0, true, "should have been triggered");
        }

        function test_dismiss() {
            skip("QTBUG-35656");
            // TODO - Remove skip once bug has been fixed. https://bugreports.qt-project.org/browse/QTBUG-35656
            mouseFlick(messageMenu2, messageMenu2.width / 2, messageMenu2.height / 2, messageMenu2.width, messageMenu2.height / 2, true, true, units.gu(1), 10);
            tryCompareFunction(function() { return signalSpyDismiss.count > 0; }, true);
        }
    }
}
