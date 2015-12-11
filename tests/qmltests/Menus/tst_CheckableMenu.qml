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

            CheckableMenu {
                id: checkMenu
                text: i18n.tr("Check")
            }
        }
    }

    SignalSpy {
        id: signalSpyTriggered
        signalName: "triggered"
        target: checkMenu
    }

    UbuntuTestCase {
        name: "CheckableMenu"
        when: windowShown

        function init() {
            checkMenu.checked = false;
            signalSpyTriggered.clear();
        }

        function test_checkChanged() {
            var checkbox = findChild(checkMenu, "checkbox");
            verify(checkbox !== undefined);

            compare(checkbox.checked, false, "Checkbox should initially be unchecked");
            checkMenu.checked = true;
            compare(checkbox.checked, true, "Checkbox should be checked");
        }

        function test_clickCheckBox() {
            var checkbox = findChild(checkMenu, "checkbox");
            verify(checkbox !== undefined);

            mouseClick(checkMenu, checkbox.width / 2, checkbox.height / 2);
            compare(signalSpyTriggered.count > 0, true, "signal checked not triggered on checkbox click");
        }

        function test_clickCheckMenu() {
            mouseClick(checkMenu, checkMenu.width / 2, checkMenu.height / 2);
            compare(signalSpyTriggered.count > 0, true, "signal checked not triggered on checkMenu click");
        }
    }
}
