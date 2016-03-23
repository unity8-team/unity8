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

    // Example plugin
    QtObject {
        id: p
        property var enrollmentProgress
        property int fingerprintCount: 0
        property bool passcodeSet: false

        signal enrollmentStopped()
        signal enrollmentStarted()
        signal enrollmentInterrupted()
        signal enrollmentCompleted()
        signal enrollmentFailed()
    }

    Component {
        id: fingerprintPage
        Fingerprint {}
    }

    PageStack {
        id: pageStack
    }

    SignalSpy {
        id: statusLabelSpy
        signalName: "slideCompleted"
    }

    UbuntuTestCase {
        name: "FingerprintPanel"
        when: windowShown

        function init() {
            pageStack.push(fingerprintPage, {
                plugin: p
            });

            p.enrollmentProgress = 0.0;
            p.fingerprintCount = 0;
            p.passcodeSet = true;

            statusLabelSpy.clear();

            var setupButton = findChild(pageStack, "fingerprintAddFingerprintButton");
            mouseClick(setupButton, setupButton.width / 2, setupButton.height / 2);
        }

        function cleanup() {
            pageStack.pop();
        }

        function test_states_data() {
            return [
                { tag: "init", signal: null, state: "" },
                { tag: "started", signal: p.enrollmentStarted, state: "reading" },
                { tag: "stopped", signal: p.enrollmentStopped, state: "" },
                { tag: "interrupted", signal: p.enrollmentInterrupted, state: "longer" },
                { tag: "completed", signal: p.enrollmentCompleted, state: "done" },
                { tag: "failed", signal: p.enrollmentFailed, state: "failed" },
            ];
        }

        function test_states(data) {
            var page = findChild(pageStack, "fingerprintSetupPage");
            if (data.signal) {
                data.signal();
            }
            compare(page.state, data.state, "unexpected state");
        }

        function test_not_done() {
            var button = findChild(pageStack, "fingerprintSetupDoneButton");
            compare(button.enabled, false, "button was enabled initially");
        }

        function test_done() {
            var button = findChild(pageStack, "fingerprintSetupDoneButton");
            p.enrollmentCompleted();
            compare(button.enabled, true, "button was disabled when done");
        }

        function test_status_label() {
            var page = findChild(pageStack, "fingerprintSetupPage");
            var statusLabel = findChild(page, "fingerprintStatusLabel");

            statusLabelSpy.target = statusLabel;

            statusLabel.setText("foo");
            statusLabelSpy.wait();
            compare(statusLabel.text, "foo");
        }
    }
}
