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
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Settings.Fingerprint 0.1
import Biometryd 0.0

Page {
    id: root
    objectName: "fingerprintPage"

    title: i18n.dtr("ubuntu-settings-components", "Fingerprint ID")


    property var ts: Biometryd.defaultDevice.templateStore
    property var sizeOperation: null
    property var enrollmentOperation: null
    property var clearanceOperation: null
    property Dialog diag: null
    property bool passcodeSet: false
    property int storedFingerprints: 0
    property var setupPage: null

    function enroll () {
        enrollmentOperation = ts.enroll(user);
        enrollmentOperation.start(enrollmentObserver);
    }

    function cancel () {
        if (enrollmentOperation !== null)
            enrollmentOperation.cancel();
    }

    function remove() {
        clearanceOperation = ts.clear(user);
        clearanceOperation.start(clearanceObserver);
    }

    signal requestPasscode()

    Component.onCompleted: {
        // Start a size operation immediately.
        sizeOperation = ts.size(user);
        sizeOperation.start(sizeObserver);
    }

    Component.onDestruction: {
        if (enrollmentOperation !== null)
            enrollmentOperation.cancel();

        if (sizeOperation !== null)
            sizeOperation.cancel();

        if (clearanceOperation !== null)
            clearanceOperation.cancel();
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
            when: !passcodeSet
        }
    ]

    Flickable {
        id: content
        anchors {
            fill: parent
            topMargin: units.gu(2)
        }
        boundsBehavior: (contentHeight > root.height) ?
                            Flickable.DragAndOvershootBounds :
                            Flickable.StopAtBounds
        contentHeight: contentItem.childrenRect.height

        Column {
            anchors {
                left: parent.left
                right: parent.right
                margins: units.gu(2)
            }
            spacing: units.gu(3)

            Column {
                id: setupPasscode

                anchors { left: parent.left; right: parent.right }
                spacing: units.gu(1)
                visible: false

                Label {
                    anchors { left: parent.left; right: parent.right }
                    text: i18n.dtr(
                        "ubuntu-settings-components",
                        "You must set a passcode to use fingerprint ID"
                    )
                }

                Button {
                    objectName: "fingerprintSetPasscodeButton"
                    onClicked: root.requestPasscode()
                    text: i18n.dtr("ubuntu-settings-components",
                                   "Set Passcode…")
                }
            }

            Column {
                id: setupFingerprint

                anchors { left: parent.left; right: parent.right }
                objectName: "fingerprintSetupEntry"
                property bool enabled: true
                property int count: root.storedFingerprints
                spacing: units.gu(1)

                Label {
                    enabled: parent.enabled
                    objectName: "fingerprintFingerprintCount"

                    readonly property string one: i18n.dtr(
                        "ubuntu-settings-components",
                        "One fingerprint registered."
                    )
                    readonly property string two: i18n.dtr(
                        "ubuntu-settings-components",
                        "Two fingerprints registered."
                    )
                    readonly property string three: i18n.dtr(
                        "ubuntu-settings-components",
                        "Three fingerprints registered."
                    )
                    readonly property string four: i18n.dtr(
                        "ubuntu-settings-components",
                        "Four fingerprints registered."
                    )
                    readonly property string five: i18n.dtr(
                        "ubuntu-settings-components",
                        "Five fingerprints registered."
                    )
                    readonly property string six: i18n.dtr(
                        "ubuntu-settings-components",
                        "Six fingerprints registered."
                    )
                    readonly property string seven: i18n.dtr(
                        "ubuntu-settings-components",
                        "Seven fingerprints registered."
                    )
                    readonly property string eight: i18n.dtr(
                        "ubuntu-settings-components",
                        "Eight fingerprints registered."
                    )
                    readonly property string nine: i18n.dtr(
                        "ubuntu-settings-components",
                        "Nine fingerprints registered."
                    )

                    function getNaturalNumber(fpc) {
                        switch (fpc) {
                        case 1:
                            return one;
                        case 2:
                            return two;
                        case 3:
                            return three;
                        case 4:
                            return four;
                        case 5:
                            return five;
                        case 6:
                            return six;
                        case 7:
                            return seven;
                        case 8:
                            return eight;
                        case 9:
                            return nine;
                        default:
                            return fpc.toString();
                        }
                    }

                    text: {
                        var count = parent.count;
                        if (count == 0) {
                            return i18n.dtr("ubuntu-settings-components",
                                            "No fingerprints registered.");
                        } else if (count > 0 && count < 10) {
                            return getNaturalNumber(count);
                        } else {
                            // TRANSLATORS: %1 is the number of stored fingerprints > 9 (i.e. always plural)
                            return i18n.dtr("ubuntu-settings-components",
                                            "%1 fingerprints registered.")
                                            .arg(count);
                        }
                    }
                }

                Button {
                    enabled: parent.enabled
                    objectName: "fingerprintAddFingerprintButton"
                    onClicked: {
                        setupPage = pageStack.push(Qt.resolvedUrl("Setup.qml"));
                        root.enroll();
                    }
                    text: i18n.dtr("ubuntu-settings-components",
                                   "Add Fingerprint…")
                }

                Button {
                    enabled: parent.enabled && root.storedFingerprints
                    objectName: "fingerprintRemoveAllButton"
                    onClicked: diag = PopupUtils.open(removeAllAlert)
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
                    onClicked: root.remove()
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
        target: setupPage
        onEnroll: enroll()
        onCanceled: cancel()
    }

    Observer {
        id: enrollmentObserver
        objectName: "enrollmentObserver"
        onFailed: {
            setupPage.enrollmentFailed(reason);
            enrollmentOperation = null;
        }
        onProgressed: {
            // biometryd API users can use details to receive
            // device/operation-specific information about the
            // operation. We illustrate the case of a FingerprintReader here.
            // console.log("enrollmentObserver: progressed: ", percent);

            var isFingerPresent             = details[FingerprintReader.isFingerPresent]
            var hasMainClusterIdentified    = details[FingerprintReader.hasMainClusterIdentified]
            var suggestedNextDirection      = details[FingerprintReader.suggestedNextDirection]
            var masks                       = details[FingerprintReader.masks]
            var estimatedFingerSize         = details[FingerprintReader.estimatedFingerSize]
            setupPage.enrollmentProgressed(percent, details);

            console.log("isFingerPresent:",            isFingerPresent,
                        "hasMainClusterIdentified:",   hasMainClusterIdentified,
                        "suggestedNextDirection:",     suggestedNextDirection,
                        "masks:",                      masks,
                        "estimatedFingerSize",         estimatedFingerSize);
        }
        onSucceeded: {
            root.storedFingerprints = root.storedFingerprints + 1;
            setupPage.enrollmentCompleted();
            enrollmentOperation = null;
        }
        onCanceled: enrollmentOperation = null
    }

    Observer {
        id: sizeObserver
        objectName: "sizeObserver"
        onFailed: {
            sizeOperation = null;
            if (diag) PopupUtils.close(diag);
            diag = PopupUtils.open(fingerprintReaderBroken);
            console.error("Biometry size operation failed:", reason);
        }
        onSucceeded: {
            root.storedFingerprints = result;
            sizeOperation = null;
        }
        onCanceled: sizeOperation = null
    }

    Observer {
        id: clearanceObserver
        objectName: "clearanceObserver"
        onFailed: {
            clearanceOperation = null;
            if (diag) PopupUtils.close(diag);
            diag = PopupUtils.open(fingerprintReaderBroken);
            console.error("Biometry clearance failed:", reason);
        }
        onSucceeded: {
            clearanceOperation = null;
            root.storedFingerprints = 0;
            if (diag) PopupUtils.close(diag);
        }
        onCanceled: clearanceOperation = null
    }

    Connections {
        target: setupPage
        onEnroll: root.enroll()
        onCancel: root.cancel()
    }

    UbuntuSettingsFingerprint {
        id: fp
    }

    User {
        id: user
        uid: fp.uid
    }
}
