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
import Ubuntu.Test 0.1
import Ubuntu.Settings.Fingerprint 0.1
import Biometryd 0.0

Item {
    id: testRoot
    width: units.gu(50)
    height: units.gu(90)

    Fingerprint {
        id: fingerprintPage
        anchors.fill: parent
    }

    SignalSpy {
        id: setPasscodeSpy
        target: fingerprintPage
        signalName: "requestPasscode"
    }

    SignalSpy {
        id: sizeSuccessSpy
        target: null
        signalName: "succeeded"
    }

    SignalSpy {
        id: clearanceSuccessSpy
        target: null
        signalName: "succeeded"
    }

    UbuntuTestCase {
        name: "FingerprintPanel"
        when: windowShown

        function init() {
            setPasscodeSpy.clear();
        }

        function test_fingerprint_set_count() {
            var sizeObserver = findInvisibleChild(fingerprintPage,
                                                  "sizeObserver");
            sizeObserver.mockSize(100, "");

            var sizeLabel = findChild(fingerprintPage,
                                      "fingerprintFingerprintCount");
            compare(sizeLabel.text, i18n.dtr("ubuntu-settings-components",
                                             "%1 fingerprints registered.")
                                             .arg(100)
            );
        }

        function test_passcode_not_set() {
            fingerprintPage.passcodeSet = false;
            compare(fingerprintPage.state, "noPasscode", "page did not have noPasscode state with no passcode set");

            var setButton = findChild(fingerprintPage, "fingerprintSetPasscodeButton");
            compare(setButton.visible, true, "button should not be visible with no passcode set");

            var setupEntry = findChild(fingerprintPage, "fingerprintSetupEntry");
            compare(setupEntry.enabled, false, "setup entry should be disabled with passcode set");
        }

        function test_passcode_set() {
            fingerprintPage.passcodeSet = true;
            compare(fingerprintPage.state, "", "page did not have clean state with passcode set");

            var setButton = findChild(fingerprintPage, "fingerprintSetPasscodeButton");
            compare(setButton.visible, false, "passcode button visible even though passcode set");

            var setupEntry = findChild(fingerprintPage, "fingerprintSetupEntry");
            compare(setupEntry.enabled, true, "setup entry was not enabled even though passcode set");
        }

        function test_set_passcode() {
            fingerprintPage.passcodeSet = false;
            var setButton = findChild(fingerprintPage, "fingerprintSetPasscodeButton");
            mouseClick(setButton, setButton.width / 2, setButton.height / 2);
            setPasscodeSpy.wait();
            compare(setPasscodeSpy.count, 1, "requesting pass code did not result in signal");
        }

        function test_fingerprint_count_data() {
            return [
                { count: 0, natural: i18n.dtr("ubuntu-settings-components",
                                              "No fingerprints registered.") },
                { count: 1, natural: i18n.dtr("ubuntu-settings-components",
                                              "One fingerprint registered.") },
                { count: 2, natural: i18n.dtr("ubuntu-settings-components",
                                              "Two fingerprints registered.") },
                { count: 11, natural: i18n.dtr("ubuntu-settings-components",
                                              "%1 fingerprints registered.")
                                              .arg(11) }
            ]
        }

        function test_fingerprint_count(data) {
            fingerprintPage.storedFingerprints = data.count;
            var c = findChild(fingerprintPage, "fingerprintFingerprintCount");
            var naturalNumber = c.getNaturalNumber(data.count);


            if (data.count > 0 && data.count < 10) {
                compare(naturalNumber, data.natural,
                        "natural number not as expected");
            } else {
                compare(parseInt(naturalNumber, 10), data.count,
                        "non-natural number not as expected");
            }
            compare(c.text, data.natural);
        }

        function test_setup_no_passcode() {
            fingerprintPage.passcodeSet = false;
            var add = findChild(fingerprintPage, "fingerprintAddFingerprintButton");
            var remove = findChild(fingerprintPage, "fingerprintRemoveAllButton");
            compare(add.enabled, false, "add button enabled even though no passcode set");
            compare(remove.enabled, false, "remove button enabled even though no passcode set");
        }

        function test_remove_when_no_fingerprints() {
            fingerprintPage.passcodeSet = true;
            fingerprintPage.storedFingerprints = 0;
            var remove = findChild(fingerprintPage, "fingerprintRemoveAllButton");
            compare(remove.enabled, false, "remove button enabled even though no fingerprints");
        }

        function test_x_remove_fingerprints() {
            fingerprintPage.passcodeSet = true;
            fingerprintPage.storedFingerprints = 1;

            // Open the remove confirmation dialog.
            var remove = findChild(fingerprintPage, "fingerprintRemoveAllButton");
            mouseClick(remove, remove.width / 2, remove.height / 2);

            // Click yes, but also let the clearance operation succeed.
            var diag = findChild(testRoot, "fingerprintRemoveAllDialog");
            var confirm = findChild(diag, "fingerprintRemoveAllConfirmationButton");
            compare(confirm.visible, true, "confirm removal button not visible (i.e. the dialog failed?)");
            mouseClick(confirm, confirm.width / 2, confirm.height / 2);
            var clearanceObserver = findInvisibleChild(fingerprintPage,
                                                       "clearanceObserver");
            clearanceSuccessSpy.target = clearanceObserver;
            clearanceObserver.mockClearance("");
            clearanceSuccessSpy.wait();

            compare(fingerprintPage.storedFingerprints, 0);
        }
    }
}
