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

pragma Singleton
import QtQuick 2.2

Item {
    property int uid: 1000
    property url path: internal.paths[uid % 4][internal.index]

    onUidChanged: internal.index = 0

    // for testing purpose
    signal nextEmitted

    function next() {
        nextEmitted()
        if (internal.index < internal.paths[uid % 4].length - 1)
            internal.index++;
        else
            internal.index = 0;
    }

    QtObject {
        id: internal
        property int index: 0
        property var paths: [
            ["../../../../tests/data/infographics/infographics-test-01.png",
             "../../../../tests/data/infographics/infographics-test-02.png"],
            ["../../../../tests/data/infographics/infographics-test-03.png",
             "../../../../tests/data/infographics/infographics-test-04.png"],
            ["../../../../tests/data/infographics/infographics-test-05.png",
             "../../../../tests/data/infographics/infographics-test-06.png"],
            ["../../../../tests/data/infographics/infographics-test-07.png"]
        ]
    }
}
