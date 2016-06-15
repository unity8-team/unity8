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
        id: setupComponent

        Setup {
            anchors.fill: parent
            visible: false
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
        signalName: "progressed"
    }

    SignalSpy {
        id: enrollmentObserverSucceededSpy
        signalName: "succeeded"
    }

    SignalSpy {
        id: enrollmentObserverFailedSpy
        signalName: "failed"
    }

    UbuntuTestCase {
        name: "SetupUI"
        when: windowShown

        property var setupInstance: null

        function init() {
            Biometryd.setAvailable(true);
            setupInstance = setupComponent.createObject(testRoot);
            pageStack.push(setupInstance);

            statusLabelSpy.target = getStatusLabel();
        }

        function cleanup() {
            statusLabelSpy.clear();

            pageStack.pop();
            setupInstance.destroy();
            setupInstance = null
        }

        function getStatusLabel() {
            return findChild(setupInstance, "fingerprintStatusLabel");
        }

        function getFailedVisual() {
            return findChild(setupInstance, "fingerprintFailedVisual");
        }

        function getDefaultVisual() {
            return findChild(setupInstance, "fingerprintDefaultVisual");
        }

        function getDoneVisual() {
            return findChild(setupInstance, "fingerprintDoneVisual");
        }

        function getProgressLabel() {
            return findChild(setupInstance, "fingerprintProgressLabel");
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
            setupInstance.enrollmentProgressed(0.5, {});
            statusLabelSpy.wait();
            compare(getStatusLabel().text, targetText);

            tryCompare(getDefaultVisual(), "opacity", 1);
            tryCompare(getFailedVisual(), "opacity", 0);
            tryCompare(getDoneVisual(), "opacity", 0);
        }

        function test_failedStatus() {
            var targetText = i18n.dtr("ubuntu-settings-components", "Sorry, the reader doesn’t seem to be working.");
            setupInstance.enrollmentFailed("test failure");
            compare(getStatusLabel().text, targetText);

            tryCompare(getDefaultVisual(), "opacity", 0);
            tryCompare(getFailedVisual(), "opacity", 1);
            tryCompare(getDoneVisual(), "opacity", 0);
        }

        function test_successfulState() {
            var targetText = i18n.dtr("ubuntu-settings-components", "All done!");

            setupInstance.enrollmentCompleted();
            compare(getStatusLabel().text, targetText);

            tryCompare(getDefaultVisual(), "opacity", 0);
            tryCompare(getFailedVisual(), "opacity", 0);
            tryCompare(getDoneVisual(), "opacity", 1);

            var button = findChild(pageStack, "fingerprintSetupDoneButton");
            compare(button.enabled, true, "button was disabled when done");
        }

        function test_notDone() {
            var button = findChild(pageStack, "fingerprintSetupDoneButton");
            compare(button.enabled, false, "button was enabled initially");
        }

        function test_statusLabel() {
            getStatusLabel().setText("foo");
            statusLabelSpy.wait();
            compare(getStatusLabel().text, "foo");
        }

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
            var vis = findChild(setupInstance, "fingerprintDirectionVisual");
            var hints = {};
            hints[FingerprintReader.suggestedNextDirection] = data.dir;

            setupInstance.enrollmentProgressed(0.5, hints);

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
            setupInstance.enrollmentProgressed(0.5, {});
            tryCompare(pl, "opacity", 1);
            tryCompare(pl, "text", i18n.dtr("ubuntu-settings-components", "%1%").arg(50));
        }

        function test_progressReadable() {
            setupInstance.enrollmentProgressed(0.6666666667, {});
            tryCompare(getProgressLabel(), "text", i18n.dtr("ubuntu-settings-components", "%1%").arg(66));
        }

        // This is a visual test where we can confirm that the arrow
        // rotates using the orthodromic distance.
        function test_directions() {
            var hints = {};

            hints[FingerprintReader.suggestedNextDirection] = FingerprintReader.North;
            setupInstance.enrollmentProgressed(0.6666666667, hints);
            wait(200)
            hints[FingerprintReader.suggestedNextDirection] = FingerprintReader.East;
            setupInstance.enrollmentProgressed(0.6666666667, hints);
            wait(200)
            hints[FingerprintReader.suggestedNextDirection] = FingerprintReader.South;
            setupInstance.enrollmentProgressed(0.6666666667, hints);
            wait(200)
            hints[FingerprintReader.suggestedNextDirection] = FingerprintReader.West;
            setupInstance.enrollmentProgressed(0.6666666667, hints);
            wait(200)
            hints[FingerprintReader.suggestedNextDirection] = FingerprintReader.SouthEast;
            setupInstance.enrollmentProgressed(0.6666666667, hints);
            wait(200)
            hints[FingerprintReader.suggestedNextDirection] = FingerprintReader.NorthEast;
            setupInstance.enrollmentProgressed(0.6666666667, hints);
            wait(200)
            hints[FingerprintReader.suggestedNextDirection] = FingerprintReader.NorthWest;
            setupInstance.enrollmentProgressed(0.6666666667, hints);
            wait(200)
            hints[FingerprintReader.suggestedNextDirection] = FingerprintReader.NorthEast;
            setupInstance.enrollmentProgressed(0.6666666667, hints);
            wait(200)
        }
    }
}
