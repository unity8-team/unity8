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

        function init () {
            pageStack.push(fingerprintPage);

            var setupButton = findChild(pageStack, "fingerprintAddFingerprintButton");
            mouseClick(setupButton, setupButton.width / 2, setupButton.height / 2);

            statusLabelSpy.target = getStatusLabel();
        }

        function cleanup () {
            // Pop fingerprint and setup pages.
            pageStack.pop();
            pageStack.pop();
            statusLabelSpy.clear();
        }

        function getStatusLabel () {
            return findChild(getSetupPage(), "fingerprintStatusLabel");
        }

        function getSetupPage () {
            return findChild(pageStack, "fingerprintSetupPage");
        }

        function getFingerprintPage () {
            return findChild(testRoot, "fingerprintPage");
        }

        function getEnrollmentObserver () {
            return findInvisibleChild(getFingerprintPage(), "enrollmentObserver");
        }

        function getFailedVisual () {
            return findChild(getSetupPage(), "fingerprintFailedVisual");
        }

        function getDefaultVisual () {
            return findChild(getSetupPage(), "fingerprintDefaultVisual");
        }

        function getDoneVisual () {
            return findChild(getSetupPage(), "fingerprintDoneVisual");
        }

        function test_initialState () {
            var targetText = i18n.dtr("ubuntu-settings-components", "Place your finger on the home button.");
            compare(getStatusLabel().text, targetText);

            verify(getDefaultVisual().visible);
            verify(!getFailedVisual().visible);
            verify(!getDoneVisual().visible);
        }

        function test_startedState () {
            var targetText = i18n.dtr("ubuntu-settings-components", "Lift and press your finger again.");
            getEnrollmentObserver().mockEnrollProgress(0.5, {});
            statusLabelSpy.wait();
            compare(getStatusLabel().text, targetText);

            verify(getDefaultVisual().visible);
            verify(!getFailedVisual().visible);
            verify(!getDoneVisual().visible);
        }

        function test_failedStatus () {
            var targetText = i18n.dtr("ubuntu-settings-components", "Sorry, the reader doesn’t seem to be working.");
            getEnrollmentObserver().mockEnroll("test failure");
            statusLabelSpy.wait();
            compare(getStatusLabel().text, targetText);

            verify(!getDefaultVisual().visible);
            verify(getFailedVisual().visible);
            verify(!getDoneVisual().visible);
        }

        function test_successfulState () {
            var targetText = i18n.dtr("ubuntu-settings-components", "All done!");
            getEnrollmentObserver().mockEnroll("");
            statusLabelSpy.wait();
            compare(getStatusLabel().text, targetText);

            verify(!getDefaultVisual().visible);
            verify(!getFailedVisual().visible);
            verify(getDoneVisual().visible);
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
    }
}
