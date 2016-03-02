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

Item {
    id: root

    /*!
       The source of the icon to display.
       \qmlproperty url source
    */
    property url source

    /*!
       The color that all pixels that originally are of color \l keyColor should take.
       \qmlproperty color color
    */
    property alias color: colorizedImage.keyColorOut

    /*!
       The color of the pixels that should be colorized.
       By default it is set to #808080.
       \qmlproperty color keyColor
    */
    property alias keyColor: colorizedImage.keyColorIn

    // FIXME: should only be "status", but overriding in settings app doesn't work.
    property var sets: ["status","apps"]

    implicitWidth: image.width

    Image {
        id: image
        objectName: "image"
        anchors { top: parent.top; bottom: parent.bottom }
        sourceSize.height: height

        visible: !colorizedImage.active

        property string iconPath: "/usr/share/icons/suru/%1/scalable/%2.svg"
        property var icons: {
            if (String(root.source).match(/^image:\/\/theme/)) {
                return String(root.source).replace("image://theme/", "").split(",");
            } else return null;
        }
        property int fallback: 0
        property int setFallback: 0

        Component.onCompleted: updateSource()
        onStatusChanged: if (status == Image.Error) bump();
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
            if (icons === null) return;
            if (fallback < icons.length - 1) fallback += 1;
            else if (setFallback < root.sets.length - 1) {
                setFallback += 1;
                fallback = 0;
            } else {
                console.warn("Could not load StatusIcon with source \"%1\" and sets %2.".arg(root.source).arg(root.sets));
                return;
            }

            updateSource();
        }

        function updateSource() {
            if (icons === null) {
                source = root.source;
            } else {
                source = (root.sets && root.sets.length > setFallback) && (icons && icons.length > fallback) ?
                            iconPath.arg(root.sets[setFallback]).arg(icons[fallback]) : "";
            }
        }
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

        fragmentShader: "
            varying highp vec2 qt_TexCoord0;
            uniform sampler2D source;
            uniform highp vec4 keyColorOut;
            uniform highp vec4 keyColorIn;
            uniform lowp float threshold;
            uniform lowp float qt_Opacity;
            void main() {
                lowp vec4 sourceColor = texture2D(source, qt_TexCoord0);
                gl_FragColor = mix(vec4(keyColorOut.rgb, 1.0) * sourceColor.a, sourceColor, step(threshold, distance(sourceColor.rgb / sourceColor.a, keyColorIn.rgb))) * qt_Opacity;
            }"
    }
}
