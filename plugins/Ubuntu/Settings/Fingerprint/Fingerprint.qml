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
    title: i18n.dtr("ubuntu-settings-components", "Fingerprint ID")

    // This signal indicates that the user has requested that she to set a
    // passcode.
    signal requestPasscode()

    property bool passcodeSet: false
    property int fingerprintCount: 0

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
            when: !root.passcodeSet
        }
    ]

    Flickable {
        id: content
        anchors {
            fill: parent
            topMargin: units.gu(2)
        }
        contentHeight: contentItem.childrenRect.height
        boundsBehavior: (contentHeight > root.height) ?
                            Flickable.DragAndOvershootBounds :
                            Flickable.StopAtBounds

        Column {
            spacing: units.gu(1)
            anchors {
                left: parent.left
                right: parent.right
                margins: units.gu(2)
            }

            Column {
                id: setupPasscode
                anchors { left: parent.left; right: parent.right }
                visible: false
                spacing: units.gu(1)

                Label {
                    anchors { left: parent.left; right: parent.right }
                    text: i18n.dtr("ubuntu-settings-components", "You must set a passcode before using fingerprint ID")
                }

                Button {
                    text: i18n.dtr("ubuntu-settings-components", "Set Passcode…")
                    onClicked: root.requestPasscode()
                }
            }

            Column {
                id: setupFingerprint
                anchors { left: parent.left; right: parent.right }
                property bool enabled: true

                Label {
                    // TRANSLATORS: As in "One fingerprint registered"
                    property string one: i18n.dtr("ubuntu-settings-components", "One")
                    // TRANSLATORS: As in "Two fingerprints registered"
                    property string two: i18n.dtr("ubuntu-settings-components", "Two")
                    // TRANSLATORS: As in "Three fingerprints registered"
                    property string three: i18n.dtr("ubuntu-settings-components", "Three")
                    // TRANSLATORS: As in "Four fingerprints registered"
                    property string four: i18n.dtr("ubuntu-settings-components", "Four")
                    // TRANSLATORS: As in "Five fingerprints registered"
                    property string five: i18n.dtr("ubuntu-settings-components", "Five")
                    // TRANSLATORS: As in "Six fingerprints registered"
                    property string six: i18n.dtr("ubuntu-settings-components", "Six")
                    // TRANSLATORS: As in "Seven fingerprints registered"
                    property string seven: i18n.dtr("ubuntu-settings-components", "Seven")
                    // TRANSLATORS: As in "Eight fingerprints registered"
                    property string eight: i18n.dtr("ubuntu-settings-components", "Eight")
                    // TRANSLATORS: As in "Nine fingerprints registered"
                    property string nine: i18n.dtr("ubuntu-settings-components", "Nine")

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
                            return fpc;
                        }
                    }

                    text: {
                        var fpc = fingerprintCount;

                        if (fpc == 0) {
                            return i18n.dtr("ubuntu-settings-components", "No fingerprints registered.");
                        } else {
                            // TRANSLATORS: %1 is the number of fingerprints registered.
                            return i18n.dtr("ubuntu-settings-components", "%1 fingerprint registered.",
                                           "%1 fingerprints registered.",
                                           fpc).arg(getNaturalNumber(fpc));
                        }
                    }
                }

                Button {
                    text: i18n.dtr("ubuntu-settings-components", "Add Fingerprint…")
                    onClicked: pageStack.push(addFingerprint)
                }

                Button {
                    text: i18n.dtr("ubuntu-settings-components", "Remove All…")
                    onClicked: PopupUtils.open(removeAllAlert)
                }
            }
        }
    }

    Component {
        id: removeAllAlert

        Dialog {
            text: i18n.dtr("ubuntu-settings-components", "Are you sure you want to forget all stored fingerprints?")

            RowLayout {
                anchors { left: parent.left; right: parent.right }
                spacing: units.gu(2)

                Button {
                    text: i18n.dtr("ubuntu-settings-components", "Cancel")
                    Layout.fillWidth: true
                }

                Button {
                    text: i18n.dtr("ubuntu-settings-components", "Remove")
                    Layout.fillWidth: true
                }
            }
        }
    }


    AddFingerprint {
        id: addFingerprint
    }
}
