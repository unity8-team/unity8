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
import Biometryd 0.0

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

    SignalSpy {
        id: enrollmentObserverSucceededSpy
        target: null
        signalName: "succeeded"
    }

    SignalSpy {
        id: enrollmentObserverFailedSpy
        target: null
        signalName: "failed"
    }

    UbuntuTestCase {
        name: "SetupUI"
        when: windowShown

        function init() {
            Biometryd.setAvailable(true);
            pageStack.push(fingerprintPage);

            var setupButton = findChild(pageStack, "fingerprintAddListItemLayout");
            mouseClick(setupButton, setupButton.width / 2, setupButton.height / 2);

            statusLabelSpy.target = getStatusLabel();

        }

        function cleanup() {
            // Pop fingerprint and setup pages.
            pageStack.pop();
            pageStack.pop();
            statusLabelSpy.clear();
        }

        function getStatusLabel() {
            return findChild(getSetupPage(), "fingerprintStatusLabel");
        }

        function getSetupPage() {
            return findChild(pageStack, "fingerprintSetupPage");
        }

        function getFingerprintPage() {
            return findChild(testRoot, "fingerprintPage");
        }

        function getEnrollmentObserver() {
            return findInvisibleChild(getFingerprintPage(), "enrollmentObserver");
        }

        function getFailedVisual() {
            return findChild(getSetupPage(), "fingerprintFailedVisual");
        }

        function getDefaultVisual() {
            return findChild(getSetupPage(), "fingerprintDefaultVisual");
        }

        function getDoneVisual() {
            return findChild(getSetupPage(), "fingerprintDoneVisual");
        }

        function getProgressLabel() {
            return findChild(getSetupPage(), "fingerprintProgressLabel");
        }

        function test_initialState() {
            var targetText = i18n.dtr("ubuntu-settings-components", "Place your finger on the home button.");
            compare(getStatusLabel().text, targetText);

            tryCompare(getDefaultVisual(), "opacity", 1);
            tryCompare(getFailedVisual(), "opacity", 0);
            tryCompare(getDoneVisual(), "opacity", 0);
        }

        function test_startedState() {
            var targetText = i18n.dtr("ubuntu-settings-components", "Lift and press your finger again.");
            getEnrollmentObserver().mockEnrollProgress(0.5, {});
            statusLabelSpy.wait();
            compare(getStatusLabel().text, targetText);

            tryCompare(getDefaultVisual(), "opacity", 1);
            tryCompare(getFailedVisual(), "opacity", 0);
            tryCompare(getDoneVisual(), "opacity", 0);
        }

        function test_failedStatus() {
            var targetText = i18n.dtr("ubuntu-settings-components", "Sorry, the reader doesn’t seem to be working.");
            getEnrollmentObserver().mockEnroll("test failure");
            statusLabelSpy.wait();
            compare(getStatusLabel().text, targetText);

            tryCompare(getDefaultVisual(), "opacity", 0);
            tryCompare(getFailedVisual(), "opacity", 1);
            tryCompare(getDoneVisual(), "opacity", 0);
        }

        function test_successfulState() {
            var targetText = i18n.dtr("ubuntu-settings-components", "All done!");
            getEnrollmentObserver().mockEnroll("");
            compare(getStatusLabel().text, targetText);

            tryCompare(getDefaultVisual(), "opacity", 0);
            tryCompare(getFailedVisual(), "opacity", 0);
            tryCompare(getDoneVisual(), "opacity", 1);
        }

        function test_notDone() {
            var button = findChild(pageStack, "fingerprintSetupDoneButton");
            compare(button.enabled, false, "button was enabled initially");
        }

        function test_done() {
            var button = findChild(pageStack, "fingerprintSetupDoneButton");
            getEnrollmentObserver().mockEnroll("");
            compare(button.enabled, true, "button was disabled when done");
        }

        function test_statusLabel() {
            getStatusLabel().setText("foo");
            statusLabelSpy.wait();
            compare(getStatusLabel().text, "foo");
        }

        // function test_fingerPresent() {
        //     var eobs = getEnrollmentObserver();
        //     var up = findChild(getSetupPage(), "fingerprintUpVisual");
        //     var down = findChild(getSetupPage(), "fingerprintDownVisual");
        //     enrollmentObserverProgressedSpy.target = eobs;

        //     eobs.mockEnrollProgress(0.5, {
        //         isFingerPresent: false
        //     });
        //     enrollmentObserverProgressedSpy.wait();
        //     // verify(up.visible);
        //     // verify(!down.visible);

        //     eobs.mockEnrollProgress(0.5, {
        //         isFingerPresent: true
        //     });
        //     enrollmentObserverProgressedSpy.wait();
        //     // verify(!up.visible);
        //     // verify(down.visible);
        // }

        function test_direction_data() {
            return [
                { tag: "empty", visual: { visible: false, rotation: 0 }},
                { tag: "not available", dir: FingerprintReader.NotAvailable, visual: { visible: false, rotation: 0 }},
                { tag: "SouthWest", dir: FingerprintReader.SouthWest, visual: { visible: true, rotation: 225 }},
                { tag: "South", dir: FingerprintReader.South, visual: { visible: true, rotation: 180 }},
                { tag: "SouthEast", dir: FingerprintReader.SouthEast, visual: { visible: true, rotation: 135 }},
                { tag: "NorthWest", dir: FingerprintReader.NorthWest, visual: { visible: true, rotation: 315 }},
                { tag: "North", dir: FingerprintReader.North, visual: { visible: true, rotation: 0 }},
                { tag: "NorthEast", dir: FingerprintReader.NorthEast, visual: { visible: true, rotation: 45 }},
                { tag: "East", dir: FingerprintReader.East, visual: { visible: true, rotation: 90 }},
                { tag: "West", dir: FingerprintReader.West, visual: { visible: true, rotation: 270 }}
            ]
        }

        function test_direction(data) {
            var eobs = getEnrollmentObserver();
            var vis = findChild(getSetupPage(), "fingerprintDirectionVisual");

            var hints = {};
            hints[FingerprintReader.suggestedNextDirection] = data.dir;

            enrollmentObserverProgressedSpy.target = eobs;
            eobs.mockEnrollProgress(0.5, hints);
            enrollmentObserverProgressedSpy.wait();

            tryCompare(vis, "opacity", data.visual.visible ? 1 : 0)
            compare(vis.opacity, data.visual.visible ? 1 : 0);
            compare(vis.rotation, data.visual.rotation);
        }

        function test_progressHidden() {
            var pl = getProgressLabel();
            compare(pl.opacity, 0);
        }

        function test_progressVisible() {
            var pl = getProgressLabel();
            getEnrollmentObserver().mockEnrollProgress(0.5, {});
            tryCompare(pl, "opacity", 1);
            tryCompare(pl, "text", i18n.dtr("ubuntu-settings-components", "%1%").arg(50));
        }

        function test_progressReadable() {
            getEnrollmentObserver().mockEnrollProgress(0.6666666667, {});
            tryCompare(getProgressLabel(), "text", i18n.dtr("ubuntu-settings-components", "%1%").arg(66));
        }
    }
}
