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

import QtQuick 2.0

ShaderEffect {
    id: root

    implicitWidth: image.width

    property string source
    property var sets: [ "status" ]

    property Image sourceImage: image.status == Image.Ready ? image : null
    property color keyColorOut: "#CCCCCC"
    property color keyColorIn: "#808080"
    property real threshold: 0.1

    fragmentShader: "
        varying highp vec2 qt_TexCoord0;
        uniform sampler2D sourceImage;
        uniform highp vec4 keyColorOut;
        uniform highp vec4 keyColorIn;
        uniform lowp float threshold;
        uniform lowp float qt_Opacity;
        void main() {
            lowp vec4 sourceColor = texture2D(sourceImage, qt_TexCoord0);
            gl_FragColor = mix(vec4(keyColorOut.rgb, 1.0) * sourceColor.a, sourceColor, step(threshold, distance(sourceColor.rgb / sourceColor.a, keyColorIn.rgb))) * qt_Opacity;
        }"

    Image {
        id: image
        objectName: "image"
        anchors { top: parent.top; bottom: parent.bottom }
        sourceSize.height: height

        visible: false

        property string iconPath: "/usr/share/icons/suru/%1/scalable/%2.svg"
        property var icons: String(root.source).replace("image://theme/", "").split(",")
        property int fallback: 0
        property int setFallback: 0

        onStatusChanged: if (status == Image.Error) bump();

        // Needed to not introduce a binding loop on source
        Component.onCompleted: updateSource()
        onIconsChanged: reset()

        Connections {
            target: root

            onSetsChanged: image.reset()
        }

        function reset() {
            fallback = 0;
            setFallback = 0;

            updateSource();
        }

        function bump() {
            if (fallback < icons.length - 1) fallback += 1;
            else if (setFallback < root.sets.length - 1) {
                setFallback += 1;
                fallback = 0;
            }

            updateSource();
        }

        function updateSource() {
            source = (sets.length > setFallback && icons.length > fallback) ? iconPath.arg(sets[setFallback]).arg(icons[fallback]) : "";
        }
    }
}
