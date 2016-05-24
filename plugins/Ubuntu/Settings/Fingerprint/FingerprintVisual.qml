/*
 * Copyright 2016 Canonical Ltd.
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
 * Authored by Jonas G. Drange <jonas.drange@canonical.com>
 */

import QtQuick 2.4

Image {
    property var masks

    source: "image://fingerprintvisual/"
    onMasksChanged: {
        var s = "image://fingerprintvisual/";

        if (masks && masks.length) {
            masks.forEach(function (mask, i) {
                // Format is "<source>/[x1,y1,w1,h1],…,[xn,yn,wn,hn]"
                // These values are passed as JavaScript sees them, without
                // any validation.
                s += "[" + mask.x + "," + mask.y + ","
                     + mask.width + "," + mask.height + "]";

                // Add comma if not last mask.
                if (i !== (masks.length - 1))
                    s += ",";
            });
        }
        source = s;
    }

    // Repeater {
    //     model: parent.masks

    //     // For testing.
    //     Rectangle {
    //         color: "#20000000"
    //         x: modelData.x
    //         y: modelData.y
    //         width: modelData.width
    //         height: modelData.height
    //     }
    // }
}
