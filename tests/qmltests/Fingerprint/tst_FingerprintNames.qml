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
import Ubuntu.Components 1.3
import Biometryd 0.0
import GSettings 1.0

Item {
    id: testRoot
    width: units.gu(50)
    height: units.gu(90)

    PageStack {
        id: pageStack
    }

    Component {
        id: fingerprintsComponent

        Fingerprints {
            anchors.fill: parent
            visible: false
        }
    }

    Component {
        id: fingerprintComponent

        Fingerprint {
            anchors.fill: parent
            visible: false
        }
    }

    Component {
        id: gsettingsComponent

        GSettings {
            schema.id: "com.ubuntu.touch.system"
        }
    }

    UbuntuTestCase {
        name: "TestOverview"
        when: windowShown

        property var pageInstance: null
        property var gsettingsInstance: null

        function getTemplateEntry(i) {
            var id = "fingerprintInstance-" + i;
            return findChild(pageInstance, id);
        }

        function getListObserver() {
            return findInvisibleChild(pageInstance, "listObserver");
        }

        function getRemovalObserver() {
            return findInvisibleChild(pageInstance, "removalObserver");
        }

        function getClearanceObserver() {
            return findInvisibleChild(pageInstance, "clearanceObserver");
        }

        function getEnrollmentObserver() {
            return findInvisibleChild(pageInstance, "enrollmentObserver");
        }

        function initTestCase() {
            Biometryd.setAvailable(true);
        }

        function init() {
            gsettingsInstance = gsettingsComponent.createObject(testRoot);
            pageInstance = fingerprintsComponent.createObject(testRoot, {
                _settings: gsettingsInstance,
                passcodeSet: true
            });
            pageStack.push(pageInstance);
        }

        function test_listSort() {
            GSettingsController.setFingerprintNames({
                "first": "A finger",
                "second": "Big finger",
                "last": "Zmall finger",
            });
            compare(getTemplateEntry(0).title.text, "A finger");
            compare(getTemplateEntry(1).title.text, "Big finger");
            compare(getTemplateEntry(2).title.text, "Zmall finger");
        }

        function test_remoteRemoval() {
            GSettingsController.setFingerprintNames({
                "tmplId": "name"
            });
            verify(getTemplateEntry(0));

            GSettingsController.setFingerprintNames({});
            verify(!getTemplateEntry(0));
        }

        function test_remoteAddition() {
            GSettingsController.setFingerprintNames({
                "tmplId": "name"
            });
            verify(getTemplateEntry(0));

            GSettingsController.setFingerprintNames({
                "tmplId": "name",
                "tmplId2": "name2"
            });
            verify(getTemplateEntry(0));
            verify(getTemplateEntry(1));
        }

        function test_remoteRename() {
            GSettingsController.setFingerprintNames({
                "tmplId": "My finger",
            });
            compare(getTemplateEntry(0).title.text, "My finger");
            GSettingsController.setFingerprintNames({
                "tmplId": "Your finger",
            });
            compare(getTemplateEntry(0).title.text, "Your finger");
        }

        function test_localRemoval() {
            GSettingsController.setFingerprintNames({
                "tmplId": "name"
            });
            verify(getTemplateEntry(0));
            pageInstance.removeTemplate("tmplId");
            verify(!getTemplateEntry(0));
        }

        function test_localAddition() {
            pageInstance.addTemplate("tmplId", "My finger");
            verify(getTemplateEntry(0));
            compare(getTemplateEntry(0).title.text, "My finger");
        }

        function test_localRename() {
            GSettingsController.setFingerprintNames({
                "tmplId": "My finger"
            });
            pageInstance.renameTemplate("tmplId", "Your finger");
            verify(getTemplateEntry(0));
            compare(getTemplateEntry(0).title.text, "Your finger");
        }

        function test_createTemplateName() {
            GSettingsController.setFingerprintNames({
                "tmplId": i18n.dtr("ubuntu-settings-components", "Finger %1").arg(1)
            });
            compare(pageInstance.createTemplateName(), i18n.dtr("ubuntu-settings-components", "Finger %1").arg(2));
            pageInstance.renameTemplate("tmplId", i18n.dtr("ubuntu-settings-components", "Finger %1").arg(2));
            compare(pageInstance.createTemplateName(), i18n.dtr("ubuntu-settings-components", "Finger %1").arg(1));
        }

        function test_assignNames() {
            var templateIds = ["tmplId0", "tmplId1", "tmplId2"];

            // This name shouldn't be overwritten
            GSettingsController.setFingerprintNames({
                "tmplId1": "My finger"
            });

            getListObserver().mockList(templateIds, "");

            verify(getTemplateEntry(0));
            compare(getTemplateEntry(0).title.text, i18n.dtr("ubuntu-settings-components", "Finger %1").arg(1));

            verify(getTemplateEntry(1));
            compare(getTemplateEntry(1).title.text, i18n.dtr("ubuntu-settings-components", "Finger %1").arg(2));

            verify(getTemplateEntry(2));
            compare(getTemplateEntry(2).title.text, "My finger");
        }

        function test_serviceRemoval() {
            GSettingsController.setFingerprintNames({
                "tmplId": "A finger"
            });
            getRemovalObserver().mockRemoval("tmplId", "");
            verify(!getTemplateEntry(0));
            compare(GSettingsController.fingerprintNames(), {});
        }

        function test_serviceEnrollment() {
            GSettingsController.setFingerprintNames({
                "tmplId1": "Existing finger"
            });
            getEnrollmentObserver().mockEnroll("tmplId2", "");

            verify(getTemplateEntry(0));
            compare(getTemplateEntry(0).title.text, "Existing finger");

            verify(getTemplateEntry(1));
            compare(getTemplateEntry(1).title.text, i18n.dtr("ubuntu-settings-components", "Finger %1").arg(1));
        }

        function test_serviceEnrollmentFirstRun() {
            var targetName = i18n.dtr("ubuntu-settings-components", "Finger %1").arg(1);

            // A test where the template id is 0.
            getEnrollmentObserver().mockEnroll(0, "");

            verify(getTemplateEntry(0));
            compare(getTemplateEntry(0).title.text, targetName);
        }

        function test_serviceEnrollmentReusesId() {
            // Test a case where enrollment processes re-uses the template id
            // Hopefully this will never happen, but it currently does in testing,
            // so test it.
            var targetName = i18n.dtr("ubuntu-settings-components", "Finger %1").arg(1);

            getEnrollmentObserver().mockEnroll(0, "");
            verify(getTemplateEntry(0));
            compare(getTemplateEntry(0).title.text, targetName);

            // Re-enroll same id, make sure it doesn't change the name
            getEnrollmentObserver().mockEnroll(0, "");
            verify(getTemplateEntry(0));
            compare(getTemplateEntry(0).title.text, targetName);

        }

        function test_serviceClearance() {
            GSettingsController.setFingerprintNames({
                "tmplId1": "A finger",
                "tmplId2": "My finger"
            });
            getClearanceObserver().mockClearance("");

            verify(!getTemplateEntry(0));
            compare(GSettingsController.fingerprintNames(), {});
        }

        function cleanup() {
            pageStack.pop();
            GSettingsController.setFingerprintNames({});
            gsettingsInstance.destroy();
            gsettingsInstance = null;
            pageInstance.destroy();
            pageInstance = null;
        }
    }

    SignalSpy {
        id: requestDeletionSpy
        signalName: "requestDeletion"
    }

    SignalSpy {
        id: requestRenameSpy
        signalName: "requestRename"
    }

    UbuntuTestCase {
        name: "TestTemplate"
        when: windowShown

        property var templateInstance: null

        function getDeleteButton() {
            return findChild(templateInstance, "templateDelete");
        }

        function getHeader() {
            return findChild(templateInstance, "templateHeader");
        }

        function getNameInput() {
            return findChild(templateInstance, "nameInput");
        }

        function getFailedDialog() {
            return findChild(testRoot, "fingerprintDeletionFailedDialog");
        }

        function getFailedDialogOk() {
            return findChild(testRoot, "fingerprintDeleteionFailedOk");
        }

        function init() {
            templateInstance = fingerprintComponent.createObject(testRoot);
            pageStack.push(templateInstance);
            requestRenameSpy.target = templateInstance;
            requestDeletionSpy.target = templateInstance;
        }

        function cleanup() {
            requestRenameSpy.clear();
            requestDeletionSpy.clear();
            pageStack.pop();
            templateInstance.destroy();
            templateInstance = null;
        }

        function test_name() {
            templateInstance.name = "My finger";
            compare(getHeader().title, "My finger");
            compare(getNameInput().text, "My finger");
        }

        function test_requestDeletion() {
            templateInstance.templateId = "tmplId";
            var button = getDeleteButton();
            mouseClick(button, button.width / 2, button.height / 2);
            requestDeletionSpy.wait();
            compare(requestDeletionSpy.count, 1);
            compare(requestDeletionSpy.signalArguments[0][0], "tmplId");
        }

        function test_requestRename() {
            templateInstance.templateId = "tmplId";
            templateInstance.name = "My finger";
            requestRenameSpy.clear();

            getNameInput().text = "Your finger";
            requestRenameSpy.wait();
            compare(requestRenameSpy.count, 1);
            compare(requestRenameSpy.signalArguments[0][0], "tmplId");
            compare(requestRenameSpy.signalArguments[0][1], "Your finger");
        }

        function test_deletionFailed() {
            templateInstance.deletionFailed();
            tryCompareFunction(function () {
                return !!getFailedDialog();
            }, true);

            var button = getFailedDialogOk();
            mouseClick(button, button.width / 2, button.height / 2);

            tryCompareFunction(function () {
                return !!getFailedDialog();
            }, false);
        }
    }
}
