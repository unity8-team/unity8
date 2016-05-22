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
            return [
                { masks: null, targetSource: src },
                { masks: [], targetSource: src },
                {
                    masks: [{x: 0, y: 0, width: 0, height: 0 }],
                    targetSource: src + "[0,0,0,0]"
                },
                {
                    masks: [{x: 0, y: 0, width: 100, height: 100 }],
                    targetSource: src + "[0,0,100,100]"
                },
                {
                    masks: [
                        {x: 0, y: 0, width: 10, height: 10 },
                        {x: 10, y: 10, width: 10, height: 10 },
                    ],
                    targetSource: src + "[0,0,10,10],[10,10,10,10]"
                },
                {
                    masks: [
                        {x: 0, y: 0, width: 10, height: 10 },
                        {x: 10, y: 10, width: 10, height: 10 },
                        {x: 20, y: 20, width: 20, height: 20 },
                    ],
                    targetSource: src + "[0,0,10,10],[10,10,10,10],[20,20,20,20]"
                },
                {
                    masks: [{x: 0, y: 0, width: vis.width, height: vis.height }],
                    targetSource: src + "[0,0,"+vis.width+"," + vis.height + "]"
                },
                {
                    masks: [
                        {x: null, y: "-a", width: "0x1", height: true },
                        {},
                    ],
                    targetSource: src + "[null,-a,0x1,true],[undefined,undefined,undefined,undefined]",
                    tag: "bad values"
                }
            ]
        }

        function test_masks (data) {
            vis.masks = data.masks;
            compare(vis.source, data.targetSource);
        }
    }
}
