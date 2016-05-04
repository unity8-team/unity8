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
 */

import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

Page {
    id: root
    objectName: "fingerprintPage"

    title: i18n.dtr("ubuntu-settings-components", "Fingerprint ID")

    /*!
        \qmlsignal requestPasscode

        This signal is emitted when the user has requested that a passcode
        be set. A passcode is a prerequisite for the enrollment process, so
        some UI will not be enabled without one.
    */
    signal requestPasscode()

    /*!
        \qmlsignal fingerprintEnrolled

        This signal is emitted when a fingerprint was successfully enrolled.
    */
    signal fingerprintEnrolled()

    /*!
        \qmlsignal requestFingerprintsRemoval

        This signal is emitted when user requests that fingerprint be removed.
    */
    signal requestFingerprintsRemoval()

    /*!
       Whether or not the user has a passcode set, which is a prerequisite for
       fingerprint enrollment.
       \qmlproperty bool passSet
    */
    property bool passSet: plugin.passcodeSet

    // To be replaced by some proper plugin.
    property var plugin

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
            when: !root.passSet
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
                    text: i18n.dtr("ubuntu-settings-components", "You must set a passcode to use fingerprint ID")
                }

                Button {
                    objectName: "fingerprintSetPasscodeButton"
                    onClicked: root.requestPasscode()
                    text: i18n.dtr("ubuntu-settings-components", "Set Passcode…")
                }
            }

            Column {
                id: setupFingerprint

                anchors { left: parent.left; right: parent.right }
                objectName: "fingerprintSetupEntry"
                property bool enabled: true
                property int count: plugin.fingerprintCount
                spacing: units.gu(1)

                Label {
                    enabled: parent.enabled
                    objectName: "fingerprintFingerprintCount"

                    // TRANSLATORS: As in "One fingerprint registered"
                    readonly property string one: i18n.dtr("ubuntu-settings-components", "One")
                    // TRANSLATORS: As in "Two fingerprints registered"
                    readonly property string two: i18n.dtr("ubuntu-settings-components", "Two")
                    // TRANSLATORS: As in "Three fingerprints registered"
                    readonly property string three: i18n.dtr("ubuntu-settings-components", "Three")
                    // TRANSLATORS: As in "Four fingerprints registered"
                    readonly property string four: i18n.dtr("ubuntu-settings-components", "Four")
                    // TRANSLATORS: As in "Five fingerprints registered"
                    readonly property string five: i18n.dtr("ubuntu-settings-components", "Five")
                    // TRANSLATORS: As in "Six fingerprints registered"
                    readonly property string six: i18n.dtr("ubuntu-settings-components", "Six")
                    // TRANSLATORS: As in "Seven fingerprints registered"
                    readonly property string seven: i18n.dtr("ubuntu-settings-components", "Seven")
                    // TRANSLATORS: As in "Eight fingerprints registered"
                    readonly property string eight: i18n.dtr("ubuntu-settings-components", "Eight")
                    // TRANSLATORS: As in "Nine fingerprints registered"
                    readonly property string nine: i18n.dtr("ubuntu-settings-components", "Nine")

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
                            return i18n.dtr("ubuntu-settings-components", "No fingerprints registered.");
                        } else {
                            // TRANSLATORS: %1 is the number of fingerprints registered.
                            return i18n.dtr("ubuntu-settings-components", "%1 fingerprint registered.",
                                           "%1 fingerprints registered.",
                                           count).arg(getNaturalNumber(count));
                        }
                    }
                }

                Button {
                    enabled: parent.enabled
                    objectName: "fingerprintAddFingerprintButton"
                    onClicked: pageStack.push(Qt.resolvedUrl("Setup.qml"), {plugin: plugin})
                    text: i18n.dtr("ubuntu-settings-components", "Add Fingerprint…")
                }

                Button {
                    enabled: parent.enabled && plugin.fingerprintCount
                    objectName: "fingerprintRemoveAllButton"
                    onClicked: PopupUtils.open(removeAllAlert)
                    text: i18n.dtr("ubuntu-settings-components", "Remove All…")
                }
            }
        }
    }

    Component {
        id: removeAllAlert

        Dialog {
            id: removeAllAlertDialog

            objectName: "fingerprintRemoveAllDialog"
            text: i18n.dtr("ubuntu-settings-components", "Are you sure you want to forget all stored fingerprints?")

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
                    onClicked: {
                        root.requestFingerprintsRemoval();
                        PopupUtils.close(removeAllAlertDialog);
                    }
                    text: i18n.dtr("ubuntu-settings-components", "Remove")
                    Layout.fillWidth: true
                }
            }
        }
    }
}
