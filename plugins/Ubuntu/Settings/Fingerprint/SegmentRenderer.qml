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
    id: segmentRenderer

    implicitWidth: texture.width
    implicitHeight: texture.height

    function animate(segments) {
        for (var i in segments) {
            var progressPixel = progressTexture.children[segments[i]];
            if (progressPixel.progress == 0.0) {
                progressPixel.animation.start();
            }
        }
    }

    property string source
    property int segmentsCount
    property color backgroundColor: theme.palette.normal.base
    property color fillColor: theme.palette.normal.activity
    property Image texture: Image {
        source: segmentRenderer.source
    }
    property var progressTexture: progressTexture
    property int progressTextureSize: progressTexture.size

    fragmentShader: "
        varying mediump vec2 qt_TexCoord0;
        uniform lowp float qt_Opacity;
        uniform lowp vec4 backgroundColor;
        uniform lowp vec4 fillColor;
        uniform lowp sampler2D texture;
        uniform lowp sampler2D progressTexture;
        uniform lowp int progressTextureSize;

        void main() {
            lowp vec4 p = texture2D(texture, qt_TexCoord0);
            lowp float segment = p.r * 255.0;
            lowp vec4 segmentProgress = step(0.9, segment) * texture2D(progressTexture, vec2((segment - 1.0 + 0.5) / float(progressTextureSize), 0.5));
            lowp vec4 color = mix(fillColor, backgroundColor, step(segmentProgress.r, p.g));
            gl_FragColor = vec4(color.rgb, 1.0) * p.b * qt_Opacity;
        }
    "

    // TODO: not the most efficient; could be replaced with an image provider
    Row {
        id: progressTexture

        property int size: 128
        layer.enabled: true
        layer.sourceRect: Qt.rect(0, 0, size, 1)
        layer.textureSize: Qt.size(size, 1)
        layer.wrapMode: ShaderEffectSource.ClampToEdge
        visible: false

        Repeater {
            model: segmentRenderer.segmentsCount
            Rectangle {
                id: progressPixel
                width: 1
                height: 1
                color: Qt.rgba(progress, progress, progress, 1.0)
                property real progress
                property NumberAnimation animation: NumberAnimation {
                    target: progressPixel
                    property: "progress"
                    from: 0.0
                    to: 1.0
                    duration: UbuntuAnimation.SleepyDuration
                    easing: UbuntuAnimation.StandardEasing
                }
            }
        }
    }
}
