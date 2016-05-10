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

    Component {
        id: fingerprintPage
        Fingerprint {
            objectName: "fingerprintPage"
            anchors.fill: parent
            passcodeSet: true
        }
    }

    PageStack {
        id: pageStack
    }

    SignalSpy {
        id: statusLabelSpy
        signalName: "slideCompleted"
    }

    SignalSpy {
        id: enrollmentObserverProgressedSpy
        target: null
        signalName: "progressed"
    }

    UbuntuTestCase {
        name: "SetupUI"
        when: windowShown

        function init () {
            pageStack.push(fingerprintPage);

            statusLabelSpy.clear();

            var setupButton = findChild(pageStack, "fingerprintAddFingerprintButton");
            mouseClick(setupButton, setupButton.width / 2, setupButton.height / 2);
        }

        function cleanup () {
            pageStack.pop();
        }

        function getDefaultVisual () {
            var setup = findChild(testRoot, "fingerprintSetupPage");
            return findChild(setup, "fingerprintDefaultVisual");
        }

        function createTestMasks () {
            return [
                {x: 0, y: 0, height: 10, width: 10},
                {x: 20, y: 20, height: 10, width: 10},
            ]
        }

        function test_enrollmentHalfway () {
            var fpPage = findChild(testRoot, "fingerprintPage");

            var enrollmentObserver = findInvisibleChild(fpPage, "enrollmentObserver");
            enrollmentObserverProgressedSpy.target = enrollmentObserver;
            enrollmentObserver.mockEnrollProgress(0.5, {masks: createTestMasks()});
            enrollmentObserverProgressedSpy.wait();

            var visual = getDefaultVisual();
            compare(visual.enrollmentProgress, 0.5);
            compare(visual.masks, createTestMasks());
        }
    }
    // UbuntuTestCase {
    //     name: "SetupUI"
    //     when: windowShown

    //     function init() {
    //         pageStack.push(fingerprintPage);

    //         statusLabelSpy.clear();

    //         var setupButton = findChild(pageStack, "fingerprintAddFingerprintButton");
    //         mouseClick(setupButton, setupButton.width / 2, setupButton.height / 2);
    //     }

    //     function cleanup() {
    //         pageStack.pop();
    //     }

    //     function test_states_data() {
    //         return [
    //             { tag: "init", signal: null, state: "" },
    //             { tag: "started", signal: p.enrollmentProgressed, signalArgs: [0], state: "reading" },
    //             // { tag: "stopped", signal: p.enrollmentFailed, signalArgs: [0], state: "" },
    //             { tag: "interrupted", signal: p.enrollmentFailed, signalArgs: [0], state: "longer" },
    //             { tag: "completed", signal: p.enrollmentCompleted, signalArgs: [], state: "done" },
    //             { tag: "failed", signal: p.enrollmentFailed, signalArgs: [1], state: "failed" },
    //         ];
    //     }

    //     function test_states(data) {
    //         var page = findChild(pageStack, "fingerprintSetupPage");
    //         if (data.signal) {
    //             data.signal.apply(data, data.signalArgs);
    //         }
    //         compare(page.state, data.state, "unexpected state");
    //     }

    //     function test_notDone() {
    //         var button = findChild(pageStack, "fingerprintSetupDoneButton");
    //         compare(button.enabled, false, "button was enabled initially");
    //     }

    //     function test_done() {
    //         var button = findChild(pageStack, "fingerprintSetupDoneButton");
    //         p.enrollmentCompleted();
    //         compare(button.enabled, true, "button was disabled when done");
    //     }

    //     function test_statusLabel() {
    //         var page = findChild(pageStack, "fingerprintSetupPage");
    //         var statusLabel = findChild(page, "fingerprintStatusLabel");

    //         statusLabelSpy.target = statusLabel;

    //         statusLabel.setText("foo");
    //         statusLabelSpy.wait();
    //         compare(statusLabel.text, "foo");
    //     }
    // }
}
