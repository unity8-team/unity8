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
import QtQuick.Layouts 1.1
import Biometryd 0.0
import GSettings 1.0
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Settings.Fingerprint 0.1

Page {
    id: root
    objectName: "fingerprintPage"

    header: PageHeader {
        title: i18n.dtr("ubuntu-settings-components", "Fingerprint ID")
        flickable: content
    }

    property var _ts: Biometryd.defaultDevice.templateStore
    property var _enrollmentOperation: null
    property var _clearanceOperation: null
    property var _removalOperation: null
    property var _listOperation: null
    property var _setupPage: null
    property var _fpInstancePage: null
    property var _settings: sysSettings

    property Dialog _diag: null
    property bool passcodeSet: false

    function enroll () {
        _enrollmentOperation = _ts.enroll(user);
        _enrollmentOperation.start(enrollmentObserver);
    }

    function cancel () {
        if (_enrollmentOperation !== null)
            _enrollmentOperation.cancel();
    }

    function clear() {
        _clearanceOperation = _ts.clear(user);
        _clearanceOperation.start(clearanceObserver);
    }

    function removeTemplate(templateId) {
        var names = sysSettings.fingerprintNames;
        delete names[templateId];
        sysSettings.fingerprintNames = names;
    }

    function renameTemplate(templateId, newName) {
        var names = sysSettings.fingerprintNames;
        names[templateId] = newName;
        sysSettings.fingerprintNames = names;
    }

    function addTemplate(templateId, name) {
        var names = sysSettings.fingerprintNames;
        names[templateId] = name;
        sysSettings.fingerprintNames = names;
    }

    function createTemplateName() {
        var map = sysSettings.fingerprintNames;
        var currentNames = [];
        var newName;
        for (var k in map) {
            if (map.hasOwnProperty(k))
                currentNames.push(map[k]);
        }

        var i = 0;
        do {
            newName = i18n.dtr("ubuntu-settings-components",
                               "Finger %1").arg(++i); // Start at 1
        } while (currentNames.indexOf(newName) >= 0);
        return newName;
    }

    // Assign names to unnamed fingerprints. This exist because we can't
    // guarantee that all fingerprints get names (i.e. enrollment can complete
    // after System Settings closes).
    function assignNames(templateIds) {
        var names = sysSettings.fingerprintNames;
        for (var i = 0; i < templateIds.length; i++) {
            if ( !(templateIds[i] in names) || !names[templateIds[i]])
                names[templateIds[i]] = createTemplateName();
                sysSettings.fingerprintNames = names;
        }
    }

    signal requestPasscode()

    Component.onCompleted: {
        // Start a list operation immediately.
        if (Biometryd.available) {
            _listOperation = _ts.list(user);
            _listOperation.start(listObserver);
        }
    }

    Component.onDestruction: {
        if (_enrollmentOperation !== null)
            _enrollmentOperation.cancel();

        if (_clearanceOperation !== null)
            _clearanceOperation.cancel();

        if (_removalOperation !== null)
            _removalOperation.cancel();

        if (_listOperation !== null)
            _listOperation.cancel();
    }

    states: [
        State {
            name: "noPasscode"
            PropertyChanges {
                target: setupPasscode
                visible: true
            }
            PropertyChanges {
                target: setupFingerprint
                enabled: false
            }
            PropertyChanges {
                target: fingerprintsList
                enabled: false
            }
            when: !passcodeSet
        },
        State {
            name: "noScanner"
            PropertyChanges {
                target: setupFingerprint
                enabled: false
            }
            PropertyChanges {
                target: fingerprintsList
                visible: false
            }
            when: !Biometryd.available
        }
    ]

    Flickable {
        id: content
        anchors.fill: parent
        boundsBehavior: (contentHeight > root.height) ?
                            Flickable.DragAndOvershootBounds :
                            Flickable.StopAtBounds
        contentHeight: contentItem.childrenRect.height

        Column {
            anchors { left: parent.left; right: parent.right }
            // spacing: units.gu(3)

            Column {
                id: setupPasscode
                anchors { left: parent.left; right: parent.right }
                visible: false

                ListItem {
                    height: setPcodeLayout.height + (divider.visible ? divider.height : 0)
                    ListItemLayout {
                        id: setPcodeLayout
                        title.text: i18n.dtr(
                            "ubuntu-settings-components",
                            "Passcode required"
                        )
                        subtitle.text: i18n.dtr(
                            "ubuntu-settings-components",
                            "You must set a passcode to use fingerprint ID"
                        )
                        Button {
                            objectName: "fingerprintSetPasscodeButton"
                            onClicked: root.requestPasscode()
                            text: i18n.dtr(
                                "ubuntu-settings-components",
                                "Set Passcode…"
                            )
                        }
                    }
                }
            }

            Column {
                id: fingerprints
                anchors { left: parent.left; right: parent.right }

                Repeater {
                    id: fingerprintsList
                    property bool enabled: true
                    objectName: "fingerprintsList"
                    model: {
                        var map = sysSettings.fingerprintNames;
                        var m = [];
                        for (var k in map) {
                            if (map.hasOwnProperty(k)) {
                                m.push({
                                    templateId: k,
                                    name: map[k]
                                });
                            }
                        }
                        m.sort(function (a, b) {
                            if (a.name < b.name) return -1;
                            if (a.name > b.name) return 1;
                            if (a.name == b.name) return 0;
                        });
                        return m;
                    }

                    ListItem {
                        height: fpLayout.height + (divider.visible ? divider.height : 0)
                        onClicked: _fpInstancePage = pageStack.push(
                                Qt.resolvedUrl("Fingerprint.qml"), {
                                name: modelData.name,
                                templateId: modelData.templateId
                            }
                        )
                        enabled: fingerprintsList.enabled

                        ListItemLayout {
                            id: fpLayout
                            objectName: "fingerprintInstance-" + index
                            title.text: modelData.name

                            ProgressionSlot {}
                        }
                    }
                }
            }

            Column {
                id: setupFingerprint

                anchors { left: parent.left; right: parent.right }
                objectName: "fingerprintSetupEntry"
                property bool enabled: true
                spacing: units.gu(2)

                ListItem {
                    height: addFpLayout.height + (divider.visible ? divider.height : 0)
                    onClicked: {
                        _setupPage = pageStack.push(Qt.resolvedUrl("Setup.qml"));
                        root.enroll();
                    }
                    enabled: parent.enabled

                    ListItemLayout {
                        id: addFpLayout
                        objectName: "fingerprintAddListItemLayout"
                        title.text: i18n.dtr(
                            "ubuntu-settings-components",
                            "Add fingerprint"
                        )

                        ProgressionSlot {}
                    }
                }

                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    enabled: fingerprintsList.model.length > 0
                    objectName: "fingerprintRemoveAllButton"
                    onClicked: _diag = PopupUtils.open(removeAllAlert)
                    text: i18n.dtr("ubuntu-settings-components",
                                   "Remove All…")
                }
            }
        }
    }

    Component {
        id: removeAllAlert

        Dialog {
            id: removeAllAlertDialog

            objectName: "fingerprintRemoveAllDialog"
            text: i18n.dtr(
                "ubuntu-settings-components",
                "Are you sure you want to forget all stored fingerprints?"
            )

            RowLayout {
                anchors { left: parent.left; right: parent.right }
                spacing: units.gu(2)

                Button {
                    onClicked: PopupUtils.close(removeAllAlertDialog)
                    text: i18n.dtr("ubuntu-settings-components", "Cancel")
                    Layout.fillWidth: true
                }

                Button {
                    objectName: "fingerprintRemoveAllConfirmationButton"
                    onClicked: root.clear()
                    text: i18n.dtr("ubuntu-settings-components", "Remove")
                    Layout.fillWidth: true
                }
            }
        }
    }

    Component {
        id: fingerprintReaderBroken

        Dialog {
            id: fingerprintReaderBrokenDialog
            objectName: "fingerprintReaderBrokenDialog"
            text: i18n.dtr("ubuntu-settings-components",
                           "Sorry, the reader doesn’t seem to be working.")

            Button {
                objectName: "fingerprintReaderBrokenDialogOK"
                onClicked: PopupUtils.close(fingerprintReaderBrokenDialog)
                text: i18n.dtr("ubuntu-settings-components", "OK")
            }
        }
    }

    Connections {
        target: _setupPage
        onEnroll: root.enroll()
        onCancel: root.cancel()
    }

    Connections {
        target: _fpInstancePage

        onRequestDeletion: {
            _removalOperation = _ts.remove(user, templateId);
            _removalOperation.start(removalObserver);
        }
        onRequestRename: renameTemplate(templateId, name)
    }

    Observer {
        id: enrollmentObserver
        objectName: "enrollmentObserver"
        onFailed: {
            if (_setupPage)
                _setupPage.enrollmentFailed(reason);
            _enrollmentOperation = null;
            console.error("Enrollment failed", reason);
        }
        onProgressed: _setupPage.enrollmentProgressed(percent, details)
        onSucceeded: {
            if (!(result in sysSettings.fingerprintNames))
                root.addTemplate(result, root.createTemplateName());
            if (_setupPage)
                _setupPage.enrollmentCompleted();
            _enrollmentOperation = null;
        }
        onCanceled: _enrollmentOperation = null
    }

    Observer {
        id: clearanceObserver
        objectName: "clearanceObserver"
        onFailed: {
            _clearanceOperation = null;
            if (_diag) PopupUtils.close(_diag);
            _diag = PopupUtils.open(fingerprintReaderBroken);
            console.error("Biometry clearance failed:", reason);
        }
        onSucceeded: {
            _clearanceOperation = null;
            if (_diag) PopupUtils.close(_diag);
            sysSettings.fingerprintNames = {};
        }
        onCanceled: _clearanceOperation = null
    }

    Observer {
        id: removalObserver
        objectName: "removalObserver"
        onFailed: {
            _removalOperation = null;
            if (_fpInstancePage)
                _fpInstancePage.deletionFailed()
            console.error("Biometryd template deletion failed:", reason);
        }
        onSucceeded: {
            _removalOperation = null;
            if (pageStack.currentPage === _fpInstancePage)
                pageStack.pop();
            root.removeTemplate(result);
        }
        onCanceled: _removalOperation = null
    }

    Observer {
        id: listObserver
        objectName: "listObserver"
        onFailed: {
            _listOperation = null;
            if (_diag) PopupUtils.close(_diag);
            _diag = PopupUtils.open(fingerprintReaderBroken);
            console.error("Biometryd list failed:", reason);
        }
        onSucceeded: {
            _listOperation = null;
            root.assignNames(result);
        }
        onCanceled: _listOperation = null
    }

    User {
        id: user
        uid: UbuntuSettingsFingerprint.uid
    }

    GSettings {
        id: sysSettings
        objectName: "systemSettings"
        schema.id: "com.ubuntu.touch.system"
    }
}
