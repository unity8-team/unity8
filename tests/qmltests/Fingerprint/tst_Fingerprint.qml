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

Item {
    id: testRoot
    width: units.gu(50)
    height: units.gu(90)

    // Fingerprint {
    //     id: fingerprintPage
    //     plugin: p
    //     anchors.fill: parent
    // }

    // SignalSpy {
    //     id: setPasscodeSpy
    //     target: fingerprintPage
    //     signalName: "requestPasscode"
    // }

    UbuntuTestCase {
        name: "FingerprintPanel"
        when: windowShown

        function init() {
            setPasscodeSpy.clear();
        }

        // function test_passcode_not_set() {
        //     p.passcodeSet = false;
        //     compare(fingerprintPage.state, "noPasscode", "page did not have noPasscode state with no passcode set");

        //     var setButton = findChild(fingerprintPage, "fingerprintSetPasscodeButton");
        //     compare(setButton.visible, true, "button should not be visible with no passcode set");

        //     var setupEntry = findChild(fingerprintPage, "fingerprintSetupEntry");
        //     compare(setupEntry.enabled, false, "setup entry should be disabled with passcode set");
        // }

        // function test_passcode_set() {
        //     p.passcodeSet = true;
        //     compare(fingerprintPage.state, "", "page did not have clean state with passcode set");

        //     var setButton = findChild(fingerprintPage, "fingerprintSetPasscodeButton");
        //     compare(setButton.visible, false, "passcode button visible even though passcode set");

        //     var setupEntry = findChild(fingerprintPage, "fingerprintSetupEntry");
        //     compare(setupEntry.enabled, true, "setup entry was not enabled even though passcode set");
        // }

        // function test_set_passcode() {
        //     p.passcodeSet = false;
        //     var setButton = findChild(fingerprintPage, "fingerprintSetPasscodeButton");
        //     mouseClick(setButton, setButton.width / 2, setButton.height / 2);
        //     compare(setPasscodeSpy.count > 0, true, "requesting pass code did not result in signal");
        // }

        // function test_fingerprint_count_data() {
        //     return [
        //         { count: 0, natural: "0" },
        //         { count: 1, natural: i18n.dtr("ubuntu-settings-components", "One") },
        //         { count: 2, natural: i18n.dtr("ubuntu-settings-components", "Two") },
        //         { count: 11, natural: "11" }
        //     ]
        // }

        // function test_fingerprint_count(data) {
        //     p.fingerprintCount = data.count;
        //     var c = findChild(fingerprintPage, "fingerprintFingerprintCount");
        //     var naturalNumber = c.getNaturalNumber(data.count);

        //     compare(naturalNumber, data.natural, "natural number not as expected");

        //     if (data.count === 0) {
        //         compare(c.text, i18n.dtr("ubuntu-settings-components", "No fingerprints registered."));
        //     } else if (data.count === 1) {
        //         compare(c.text, i18n.dtr("ubuntu-settings-components", "One fingerprint registered."));
        //     } else {
        //         compare(
        //             c.text,
        //             i18n.dtr("ubuntu-settings-components", "%1 fingerprints registered.")
        //                 .arg(naturalNumber)
        //         );
        //     }
        // }

        // function test_setup_no_passcode() {
        //     p.passcodeSet = false;
        //     var add = findChild(fingerprintPage, "fingerprintAddFingerprintButton");
        //     var remove = findChild(fingerprintPage, "fingerprintRemoveAllButton");
        //     compare(add.enabled, false, "add button enabled even though no passcode set");
        //     compare(remove.enabled, false, "remove button enabled even though no passcode set");
        // }

        // function test_remove_when_no_fingerprints() {
        //     p.passcodeSet = true;
        //     p.fingerprintCount = 0;
        //     var remove = findChild(fingerprintPage, "fingerprintRemoveAllButton");
        //     compare(remove.enabled, false, "remove button enabled even though no fingerprints");
        // }

        // function test_remove_fingerprints() {
        //     p.passcodeSet = true;
        //     p.fingerprintCount = 1;
        //     var remove = findChild(fingerprintPage, "fingerprintRemoveAllButton");
        //     compare(remove.enabled, true, "remove button disabled even though we have fingerprints");
        //     mouseClick(remove, remove.width / 2, remove.height / 2);

        //     var diag = findChild(testRoot, "fingerprintRemoveAllDialog");
        //     var confirm = findChild(diag, "fingerprintRemoveAllConfirmationButton");
        //     compare(confirm.visible, true, "confirm removal button not visible (i.e. the dialog failed?)");
        //     mouseClick(confirm, confirm.width / 2, confirm.height / 2);

        //     compare(p.fingerprintCount, 0, "the fingerprint counter was not reset");

        //     tryCompareFunction(function () {
        //             return findChild(testRoot, "fingerprintRemoveAllDialog");
        //     }, undefined, "the dialog was not destroyed");
        // }
    }
}
