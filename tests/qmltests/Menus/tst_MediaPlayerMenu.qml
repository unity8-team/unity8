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

import QtQuick 2.0
import QtTest 1.0
import Ubuntu.Test 0.1
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

            MediaPlayerMenu {
                id: mediaPlayerMenu
            }
        }
    }

    UbuntuTestCase {
        name: "MediaPlayerMenu"
        when: windowShown

        function test_running() {
            var player = UtilsJS.findChild(mediaPlayerMenu, "player");
            var albumArt = UtilsJS.findChild(mediaPlayerMenu, "albumArt");

            var running = mediaPlayerMenu.running

            compare(player.visible, !running, "player should be not visible when running");
            compare(albumArt.visible, running, "albumn art should be visible when running");

            running = !running;
            mediaPlayerMenu.running = running;

            compare(player.visible, !running, "player should be not visible when running");
            compare(albumArt.visible, running, "albumn art should be visible when running");
        }
    }
}
