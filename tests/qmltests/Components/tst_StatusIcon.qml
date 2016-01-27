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

import QtQuick 2.4
import QtTest 1.0
import Ubuntu.Test 0.1
import Ubuntu.Settings.Components 0.1

Item {
    width: units.gu(40)
    height: units.gu(70)

    StatusIcon {
        id: icon

        height: units.gu(3)
    }

    UbuntuTestCase {
        name: "StatusIcon"
        when: windowShown

        function init() {
            icon.source = "";
            icon.sets = [ "status" ]
            waitForRendering(icon)
        }

        function test_icon() {
            icon.source = "image://theme/bar,gps,baz";

            var image = findChild(icon, "image");
            tryCompare(image, "source", "file://" + image.iconPath.arg("status").arg("gps"));
        }

        function test_iconFallback() {
            icon.source = "image://theme/foo,bar,baz";

            var image = findChild(icon, "image");
            tryCompare(image, "source", "file://" + image.iconPath.arg("status").arg("baz"));
        }

        function test_iconSets() {
            icon.source = "image://theme/bar,add,baz";
            icon.sets = [ "foo", "actions", "bar" ]

            var image = findChild(icon, "image");
            tryCompare(image, "source", "file://" + image.iconPath.arg("actions").arg("add"));
        }

        function test_iconSetsFallback() {
            icon.source = "image://theme/add,bar,baz";
            icon.sets = [ "foo", "bar", "baz" ]

            var image = findChild(icon, "image");
            tryCompare(image, "source", "file://" + image.iconPath.arg("baz").arg("baz"));
        }

        function test_iconSource() {
            var image = findChild(icon, "image");
            icon.source = image.iconPath.arg("status").arg("gps");

            tryCompare(image, "source", "file://" + image.iconPath.arg("status").arg("gps"));
        }
    }
}
