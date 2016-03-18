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
 * Authored by Andrea Cimitan <andrea.cimitan@canonical.com>
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

            ProgressBarMenu {
                id: progressBarMenu
                text: i18n.tr("ProgressBar")
            }
            ProgressBarMenu {
                id: progressBarMenu2
                anchors.top: progressBarMenu.bottom
            }
        }
    }

    TestCase {
        name: "ProgressBarMenu"
        when: windowShown

        function test_indeterminate() {
            var indeterminate = progressBarMenu.indeterminate
            progressBarMenu.indeterminate = !indeterminate
            compare(progressBarMenu.indeterminate, !indeterminate, "Cannot set indeterminate")
            progressBarMenu.indeterminate = indeterminate
        }

        function test_minimumValue() {
            progressBarMenu.minimumValue = 11
            compare(progressBarMenu.minimumValue, 11, "Cannot set minimumValue")
        }

        function test_maximumValue() {
            progressBarMenu.minimumValue = 98
            compare(progressBarMenu.minimumValue, 98, "Cannot set maximumValue")
        }

        function test_value() {
            progressBarMenu.value = 36
            compare(progressBarMenu.value, 36, "Cannot set value")
        }
    }
}
