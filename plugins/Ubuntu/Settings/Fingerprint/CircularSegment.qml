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
 * Authored by  Florian Boucault <florian.boucault@canonical.com>
 */

import QtQuick 2.4
import Ubuntu.Components 1.3

ShaderEffect {
    implicitWidth: units.gu(20)
    implicitHeight: units.gu(20)
    height: width

    property color color: "#3EB34F"
    property real thickness: units.dp(3)
    property real angleStop: 90

    property real _texturePixel: 1/width
    property real _thicknessTex: thickness/width
    property real _angleStopRadians: angleStop * (Math.PI / 180)

    fragmentShader: "
        varying mediump vec2 qt_TexCoord0;
        uniform lowp float qt_Opacity;
        uniform lowp vec4 color;
        uniform lowp float _texturePixel;
        uniform lowp float _thicknessTex;
        uniform lowp float _angleStopRadians;

        void main() {
            mediump vec2 center = vec2(0.5);
            mediump float circleX = (qt_TexCoord0.x - center.x);
            mediump float circleY = (qt_TexCoord0.y - center.y);
            mediump float distanceToCenter = circleX*circleX + circleY*circleY;
            const mediump float PI = 3.1415926535897932384626433832795;
            mediump float angle = atan(-circleX, circleY) + PI;

            mediump float radius = 0.5;
            mediump float radiusSquare = radius * radius;
            mediump float radiusInner = radius - _thicknessTex;
            mediump float radiusInnerSquare = radiusInner * radiusInner;

            lowp vec4 fillColor = mix(vec4(0),
                                      mix(color, vec4(0), smoothstep(distanceToCenter-_texturePixel, distanceToCenter+_texturePixel, radiusInnerSquare)),
                                      smoothstep(distanceToCenter-_texturePixel, distanceToCenter+_texturePixel, radiusSquare));
            fillColor = mix(fillColor, vec4(0), step(_angleStopRadians, angle));
            gl_FragColor = fillColor * qt_Opacity;
        }
    "
}

