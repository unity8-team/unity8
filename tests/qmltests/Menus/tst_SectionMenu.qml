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

            SectionMenu {
                id: section1
                text: i18n.tr("Section Starts Here: 1");
            }
            SectionMenu {
                id: section2
                text: i18n.tr("Section Starts Here: 2");
                busy: true
                anchors.top: section1.bottom
            }
        }
    }

    UbuntuTestCase {
        name: "SectionMenu"
        when: windowShown

        function init() {
            section1.busy = false;
        }

        function test_busy() {
            var indicator = findChild(section1, "indicator");
            verify(indicator.running === false);

            section1.busy = true
            compare(indicator.running, true, "Activity indicator should be animating when busy");
        }
    }
}
