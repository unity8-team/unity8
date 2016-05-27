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
import QtTest 1.0
import Ubuntu.Components 1.3
import Ubuntu.Settings.Fingerprint 0.1
import Ubuntu.Test 0.1

Item {
    id: testRoot
    width: units.gu(50)
    height: units.gu(90)

    SignalSpy {
        id: statusLabelSpy
        signalName: "slideCompleted"
    }

    FingerprintVisual {
        id: vis
        width: 400
        height: width * 1.227
        sourceSize.width: width
        sourceSize.height: height
    }

    UbuntuTestCase {
        name: "FingerprintVisual"
        when: windowShown

        function init () {
            vis.masks = null;
        }

        function test_masks_data() {
            var src = "image://fingerprintvisual/";
            var visHeight = vis.sourceSize.height;
            return [
                { masks: null, targetSource: src, tag: "null" },
                { masks: [], targetSource: src, tag: "no masks" },
                {
                    masks: [{x: 0, y: 0, width: 0, height: 0 }],
                    targetSource: src + "[400,0,0,0]",
                    tag: "0"
                },
                {
                    masks: [
                        {x: 0, y: 0, width: 0.5, height: 0.5 },
                        {x: 0.5, y: 0.5, width: 1, height: 1 },
                        {x: 1, y: 1, width: 1, height: 1 },
                    ],
                    targetSource: src + "[200,0,200,245.4],[-200,245.4,400,490.8],[-400,490.8,400,490.8]",
                    tag: "bunch"
                },
                {
                    masks: [
                        {x: null, y: "-a", width: "0x1", height: true },
                        {},
                    ],
                    targetSource: src,
                    tag: "bad values"
                },

                // // Masks that can be used for manual, visual checks.
                {
                    masks: [
                        {x: 0, y: 0, width: 0.5, height: 0.5 },
                    ],
                    visualCheck: true,
                    tag: "top right corner"
                },
                {
                    masks: [
                        {x: 0.5, y: 0, width: 0.5, height: 0.5 },
                    ],
                    visualCheck: true,
                    tag: "top left corner"
                },
                {
                    masks: [
                        {x: 0, y: 0.5, width: 0.5, height: 0.5 },
                    ],
                    visualCheck: true,
                    tag: "bottom right corner"
                },
                {
                    masks: [
                        {x: 0.5, y: 0.5, width: 0.5, height: 0.5 },
                    ],
                    visualCheck: true,
                    tag: "bottom left corner"
                },
                {
                    masks: [
                        {x: 0, y: 0, width: 0.5, height: 0.5 },
                        {x: 0.5, y: 0, width: 0.5, height: 0.5 },
                        {x: 0, y: 0.5, width: 0.5, height: 0.5 },
                        {x: 0.5, y: 0.5, width: 0.5, height: 0.5 }
                    ],
                    visualCheck: true,
                    tag: "all corners"
                }
            ]
        }

        function test_masks (data) {
            vis.masks = data.masks;
            if (data.visualCheck) {
                wait(1000);
            } else {
                compare(vis.source, data.targetSource);
            }
        }
    }
}
