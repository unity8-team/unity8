/*
 * Copyright 2014-2015 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Gestures 0.1 // For TouchGate
import Utils 0.1 // for InputWatcher
import Unity.Application 0.1 // for MirSurfaceItem
import AccountsService 0.1

FocusScope {
    id: root
    objectName: "surfaceContainer"

    property var surface: null
    property bool hadSurface: false
    property bool interactive
    property int surfaceOrientationAngle: 0
    property string name: surface ? surface.name : ""
    property bool resizeSurface: true
    property alias roundedBottomCorners: roundedBottomCornersShader.enabled

    property int requestedWidth: -1
    property int requestedHeight: -1

    property string savedKeymap: AccountsService.keymaps[0] // start with the user default

    onSurfaceChanged: {
        if (surface) {
            surfaceItem.surface = surface;
            root.hadSurface = false;
            switchToKeymap(savedKeymap);
        }
    }

    function switchToKeymap(keymap) {
        var finalKeymap = keymap.split("+");
        savedKeymap = keymap; // save the keymap in case the surface changes later

        if (surface) {
            surface.setKeymap(finalKeymap[0], finalKeymap[1] || "");
        }
    }

    InputWatcher {
        target: surfaceItem
        onTargetPressedChanged: {
            if (targetPressed && root.interactive) {
                root.focus = true;
                root.forceActiveFocus();
            }
        }
    }

    MirSurfaceItem {
        id: surfaceItem
        objectName: "surfaceItem"

        fillMode: MirSurfaceItem.PadOrCrop
        consumesInput: true

        surfaceWidth: {
            if (root.resizeSurface) {
                if (root.requestedWidth >= 0) {
                    return root.requestedWidth;
                } else {
                    return width;
                }
            } else {
                return -1;
            }
        }

        surfaceHeight: {
            if (root.resizeSurface) {
                if (root.requestedHeight >= 0) {
                    return root.requestedHeight;
                } else {
                    return height;
                }
            } else {
                return -1;
            }
        }

        enabled: root.interactive
        focus: true
        antialiasing: !root.interactive
        orientationAngle: root.surfaceOrientationAngle
        visible: !root.roundedBottomCorners
    }

    ShaderEffect {
        id: roundedBottomCornersShader
        anchors.fill: surfaceItem
        blending: false
        enabled: false

        readonly property variant surfaceItem: surfaceItem
        readonly property variant radius: units.gu(0.5)

        fragmentShader: "
        uniform sampler2D surfaceItem;
        uniform highp float width;
        uniform highp float height;
        uniform highp float radius;
        varying highp vec2 qt_TexCoord0;

        void main()
        {
            vec2 point = vec2(qt_TexCoord0.x * width, qt_TexCoord0.y * height);

            vec2 bottomLeftCircleCenter = vec2(radius, height - radius);
            if ((point.x < bottomLeftCircleCenter.x) && (point.y > bottomLeftCircleCenter.y)) {
                float dist = distance(point, bottomLeftCircleCenter);
                if (dist > radius) {
                    discard;
                }
            } else {
                vec2 bottomRightCircleCenter = vec2(width - radius, height - radius);
                if ((point.x > bottomRightCircleCenter.x) && (point.y > bottomRightCircleCenter.y)) {
                    float dist = distance(point, bottomRightCircleCenter);
                    if (dist > radius) {
                        discard;
                    }
                }
            }

            highp vec4 c = texture2D(surfaceItem, qt_TexCoord0);
            gl_FragColor = c;
        }
        "
    }

    // MirSurface size drives SurfaceContainer size
    Binding {
        target: surfaceItem; property: "width"; value: root.surface ? root.surface.size.width : 0
        when: root.requestedWidth >= 0 && root.surface
    }
    Binding {
        target: surfaceItem; property: "height"; value: root.surface ? root.surface.size.height : 0
        when: root.requestedHeight >= 0 && root.surface
    }
    Binding {
        target: root; property: "width"; value: surfaceItem.width
        when: root.requestedWidth >= 0
    }
    Binding {
        target: root; property: "height"; value: surfaceItem.height
        when: root.requestedHeight >= 0
    }

    // SurfaceContainer size drives MirSurface size
    Binding {
        target: surfaceItem; property: "width"; value: root.width
        when: root.requestedWidth < 0
    }
    Binding {
        target: surfaceItem; property: "height"; value: root.height
        when: root.requestedHeight < 0
    }


    TouchGate {
        objectName: "touchGate-"+name
        targetItem: surfaceItem
        anchors.fill: root
        enabled: surfaceItem.enabled
    }

    states: [
        State {
            name: "zombie"
            when: surfaceItem.surface && !surfaceItem.live
        }
    ]
    transitions: [
        Transition {
            from: ""; to: "zombie"
            SequentialAnimation {
                UbuntuNumberAnimation { target: surfaceItem; property: "opacity"; to: 0.0
                                        duration: UbuntuAnimation.BriskDuration }
                PropertyAction { target: surfaceItem; property: "visible"; value: false }
                ScriptAction { script: {
                    surfaceItem.surface = null;
                    root.hadSurface = true;
                } }
            }
        },
        Transition {
            from: "zombie"; to: ""
            ScriptAction { script: {
                surfaceItem.opacity = 1.0;
                surfaceItem.visible = true;
            } }
        }
    ]
}
