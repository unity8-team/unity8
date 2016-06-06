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
        id: visualReadySpy
        signalName: "ready"
    }

    Component {
        id: fingerprintVisualComp

        FingerprintVisual {
            id: vis
            objectName: "fingerprintVisual"
            width: 400
            height: width * 1.227
        }
    }


    UbuntuTestCase {
        name: "FingerprintVisual"
        when: windowShown

        function init() {
            visualReadySpy.target = fingerprintVisualComp.createObject(testRoot);
            visualReadySpy.wait()
        }

        function cleanup() {
            findChild(testRoot, "fingerprintVisual").destroy();
        }

        function test_masks_data() {
            return [
                { masks: null, targetMasks: [], tag: "null" },
                { masks: [], targetMasks: [], tag: "no masks" },
                {
                    masks: [{x: 0, y: 0, width: 0, height: 0 }],
                    targetMasks: [{x: 0, y: 0, width: 0, height: 0}],
                    tag: "0"
                },
                {
                    masks: [
                        {x: null, y: "-a", width: "0x1", height: true },
                        {},
                    ],
                    targetMasks: [],
                    tag: "bad values"
                },

                // Masks for manual, visual checks.
                {
                    masks: [
                        {x: 0, y: 0, width: 0.5, height: 0.5 }
                    ],
                    visualCheck: true,
                    tag: "top right corner"
                },
                {
                    masks: [
                        {x: 0.5, y: 0, width: 0.5, height: 0.5 }
                    ],
                    visualCheck: true,
                    tag: "top left corner"
                },
                {
                    masks: [
                        {x: 0, y: 0.5, width: 0.5, height: 0.5 }
                    ],
                    visualCheck: true,
                    tag: "bottom right corner"
                },
                {
                    masks: [
                        {x: 0.5, y: 0.5, width: 0.5, height: 0.5 }
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
            var vis = findChild(testRoot, "fingerprintVisual");
            vis.masks = data.masks;
            if (data.visualCheck) {
                wait(1000);
            } else {
                var actualMasks = vis.getMasksToEnroll();
                var targetMasks = data.targetMasks;
                compare(actualMasks.length, targetMasks.length);
            }
        }
    }
}
