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

    function relativeToAbsolute (relRect) {
        var absRect = {
            // Translate the box so as to reverse it's x coord.
            x: (1 - (relRect.x + relRect.width)) * width,
            y: relRect.y * height,
            width: relRect.width * width,
            height: relRect.height * height
        };
        console.log(1 - (relRect.x + relRect.width))
        return absRect;
    }

    // http://stackoverflow.com/a/1830844/538866
    function isNumeric (n) {
        return !isNaN(parseFloat(n)) && isFinite(n);
    }

    onMasksChanged: {
        var s = "image://fingerprintvisual/";

        if (masks && masks.length) {
            masks.forEach(function (mask, i) {
                mask = relativeToAbsolute(mask);
                // Format is "<source>/[x1,y1,w1,h1],…,[xn,yn,wn,hn]"
                // If any value is non-numeric, we drop the mask.
                if (!isNumeric(mask.x) || !isNumeric(mask.y) || !isNumeric(mask.width)
                    || !isNumeric(mask.height))
                    return;

                s += "[" + mask.x + "," + mask.y + ","
                     + mask.width + "," + mask.height + "]";

                // Add comma if not last mask.
                if (i !== (masks.length - 1))
                    s += ",";
            });
        }
        source = s;
    }

    Repeater {
        model: parent.masks

        // For testing.
        Rectangle {
            color: "#20000000"
            x: modelData.x
            y: modelData.y
            width: modelData.width
            height: modelData.height
        }
    }
}
