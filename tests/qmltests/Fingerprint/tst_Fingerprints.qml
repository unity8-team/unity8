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
import GSettings 1.0

Item {
    id: testRoot
    width: units.gu(50)
    height: units.gu(90)

    Component {
        id: fingerprintsComponent

        Fingerprints {
            anchors.fill: parent
        }
    }

    SignalSpy {
        id: spy
    }

    UbuntuTestCase {
        name: "FingerprintPanel"
        when: windowShown

        property var fingerprintsInstance: null

        function init() {
            Biometryd.setAvailable(true);
            fingerprintsInstance = fingerprintsComponent.createObject(testRoot);
        }

        function cleanup() {
            spy.clear();
            spy.target = null;
            spy.signalName = "";
            fingerprintsInstance.destroy();
            GSettingsController.setFingerprintNames({});
        }

        function getClearanceObserver() {
            return findInvisibleChild(fingerprintsInstance, "clearanceObserver");
        }

        function getListObserver() {
            return findInvisibleChild(fingerprintsInstance, "listObserver");
        }

        function getEnrollmentObserver() {
            return findInvisibleChild(fingerprintsInstance, "enrollmentObserver");
        }

        function getRemovalObserver() {
            return findInvisibleChild(fingerprintsInstance, "removalObserver");
        }

        function getBrokenDialog() {
            return findChild(testRoot, "fingerprintReaderBrokenDialog");
        }

        function getBrokenDialogOk() {
            return findChild(testRoot, "fingerprintReaderBrokenDialogOK");
        }

        function getAddFingerprintItem() {
            return findChild(fingerprintsInstance, "fingerprintAddListItemLayout");
        }

        function getRemoveAllButton() {
            return findChild(fingerprintsInstance, "fingerprintRemoveAllButton");
        }

        function getFingerprintsList() {
            return findChild(fingerprintsInstance, "fingerprintsList");
        }

        function getSetupEntry() {
            return findChild(fingerprintsInstance, "fingerprintSetupEntry");
        }

        function test_failures_data() {
            return [
                { tag: "clearance", observer: getClearanceObserver, mock: "mockClearance", mockArgs: ["failed"] },
                { tag: "list", observer: getListObserver, mock: "mockList", mockArgs: [[], "failed"] }
            ]
        }

        function test_failures(data) {
            var obs = data.observer();
            spy.signalName = "failed";
            spy.target = obs;
            obs[data.mock].apply(null, data.mockArgs);
            spy.wait();
            var errorDiag = getBrokenDialog();
            var ok = getBrokenDialogOk();
            mouseClick(ok, ok.width / 2, ok.height / 2);

            // Halt testing until dialog has been destroyed.
            tryCompareFunction(function() {
                return getBrokenDialog();
            }, null);
        }

        function test_noPasscode() {
            fingerprintsInstance.passcodeSet = false;
            compare(fingerprintsInstance.state, "noPasscode");

            var setButton = findChild(fingerprintsInstance, "fingerprintSetPasscodeButton");
            compare(setButton.visible, true);

            var setupEntry = getSetupEntry();
            compare(setupEntry.enabled, false);

            var fingerprintsList = getFingerprintsList();
            compare(fingerprintsList.enabled, false);
        }

        function test_noScanner() {
            fingerprintsInstance.passcodeSet = true;
            Biometryd.setAvailable(false);
            compare(fingerprintsInstance.state, "noScanner");

            var addItem = getAddFingerprintItem();
            compare(addItem.enabled, false);

            var removeButton = getRemoveAllButton();
            compare(removeButton.enabled, false);

            var fingerprintsList = getFingerprintsList();
            compare(fingerprintsList.visible, false);
        }

        function test_passcode() {
            fingerprintsInstance.passcodeSet = true;
            compare(fingerprintsInstance.state, "");
            var setButton = findChild(fingerprintsInstance, "fingerprintSetPasscodeButton");
            compare(setButton.visible, false);
            var setupEntry = getSetupEntry();
            compare(setupEntry.enabled, true);
        }

        function test_changePasscode() {
            fingerprintsInstance.passcodeSet = false;
            var setButton = findChild(fingerprintsInstance, "fingerprintSetPasscodeButton");

            spy.signalName = "requestPasscode"
            spy.target = fingerprintsInstance;
            mouseClick(setButton, setButton.width / 2, setButton.height / 2);
            spy.wait();

            compare(spy.count, 1);
        }

        function test_setup() {
            fingerprintsInstance.passcodeSet = false;
            var add = getAddFingerprintItem();
            var remove = getRemoveAllButton();
            compare(add.enabled, false);
            compare(remove.enabled, false);
        }

        function test_noRemove() {
            fingerprintsInstance.passcodeSet = true;
            GSettingsController.setFingerprintNames({});
            var remove = getRemoveAllButton();
            compare(remove.enabled, false);
        }

        function test_remove() {
            fingerprintsInstance.passcodeSet = true;
            GSettingsController.setFingerprintNames({"tmplId": "A Finger"});

            var remove = getRemoveAllButton();
            mouseClick(remove, remove.width / 2, remove.height / 2);
            var diag = findChild(testRoot, "fingerprintRemoveAllDialog");
            var confirm = findChild(diag, "fingerprintRemoveAllConfirmationButton");
            compare(confirm.visible, true);
            mouseClick(confirm, confirm.width / 2, confirm.height / 2);

            var obs = getClearanceObserver();
            spy.signalName = "succeeded";
            spy.target = obs;
            obs.mockClearance("");
            spy.wait();
            compare(spy.count, 1);

            // Wait for dialog destruction (which is required for other tests)
            // to function.
            tryCompareFunction(function() {
                return findChild(testRoot, "fingerprintRemoveAllDialog");
            }, null);
        }

        function test_enrollmentSucceeded() {
            var obs = getEnrollmentObserver();
            var targetFingerprintName = i18n.dtr("ubuntu-settings-components", "Finger %1").arg(1);
            spy.signalName = "succeeded";
            spy.target = obs;
            obs.mockEnroll("tmplId", "");
            spy.wait();
            compare(spy.count, 1);
            compare(spy.signalArguments[0][0], "tmplId");

            tryCompareFunction(function() {
                return GSettingsController.fingerprintNames()["tmplId"];
            }, targetFingerprintName);
        }
    }
}
