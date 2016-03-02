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

            ProgressValueMenu {
                id: progressMenu
                text: i18n.tr("Progress Value")
                iconSource: Qt.resolvedUrl("../../artwork/avatar.png")
                value: 0
            }
        }
    }

    UbuntuTestCase {
        name: "ProgressValueMenu"
        when: windowShown

        function test_label() {
            var progress = findChild(progressMenu, "progress");
            verify(progress !== undefined);

            progressMenu.value = 20;
            compare(progress.text, "20 %", "Label is not in correct format.");
        }
    }
}
