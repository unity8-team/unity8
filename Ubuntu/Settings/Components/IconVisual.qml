/*
 * Copyright 2012 Canonical Ltd.
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
 */

import QtQuick 2.0
import Ubuntu.Components 1.1

Item {
    id: icon

    property url source
    property alias color: colorizedImage.keyColorOut
    property alias keyColor: colorizedImage.keyColorIn
    property alias status: image.status

    Image {
        id: image

        /* Necessary so that icons are not loaded before a size is set. */
        property bool ready: false
        Component.onCompleted: ready = true

        anchors.fill: parent
        // don't want to try get the image until we have a valid source size.
        source: ready && sourceSize.width > 0 && sourceSize.height > 0 && icon.source ? icon.source : ""
        sourceSize {
            width: width
            height: height
        }
        cache: true
        visible: !colorizedImage.active
    }

    ShaderEffect {
        id: colorizedImage

        anchors.fill: parent
        visible: active && image.status == Image.Ready

        // Whether or not a color has been set.
        property bool active: keyColorOut != Qt.rgba(0.0, 0.0, 0.0, 0.0)

        property Image source: visible ? image : null
        property color keyColorOut: Qt.rgba(0.0, 0.0, 0.0, 0.0)
        property color keyColorIn: "#808080"
        property real threshold: 0.1

        fragmentShader: source ? "
            varying highp vec2 qt_TexCoord0;
            uniform sampler2D source;
            uniform highp vec4 keyColorOut;
            uniform highp vec4 keyColorIn;
            uniform lowp float threshold;
            uniform lowp float qt_Opacity;
            void main() {
                lowp vec4 sourceColor = texture2D(source, qt_TexCoord0);
                gl_FragColor = mix(vec4(keyColorOut.rgb, 1.0) * sourceColor.a, sourceColor, step(threshold, distance(sourceColor.rgb / sourceColor.a, keyColorIn.rgb))) * qt_Opacity;
            }" : ""
    }
}
