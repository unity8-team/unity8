/*
 * Copyright (C) 2016 Canonical, Ltd.
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
 *
 */

import QtQuick 2.4
import Utils 0.1

ShaderEffect {
    blending: false

    property variant textureItem: undefined
    property variant radius: units.gu(0.5)

    fragmentShader: "
    uniform sampler2D textureItem;
    uniform highp float width;
    uniform highp float height;
    uniform highp float radius;
    varying highp vec2 qt_TexCoord0;

    void main()
    {
        highp vec2 point = vec2(qt_TexCoord0.x * width, qt_TexCoord0.y * height);

        highp vec2 bottomLeftCircleCenter = vec2(radius, height - radius);
        if ((point.x < bottomLeftCircleCenter.x) && (point.y >= bottomLeftCircleCenter.y)) {
            highp float dist = distance(point, bottomLeftCircleCenter);
            if (dist >= radius - 1.0) {
                discard;
            }
        } else {
            highp vec2 bottomRightCircleCenter = vec2(width - radius, height - radius);
            if ((point.x > bottomRightCircleCenter.x) && (point.y >= bottomRightCircleCenter.y)) {
                highp float dist = distance(point, bottomRightCircleCenter);
                if (dist >= radius - 1.0) {
                    discard;
                }
            }
        }

        highp vec4 c = texture2D(textureItem, qt_TexCoord0);
        gl_FragColor = c;
    }
    "
}
