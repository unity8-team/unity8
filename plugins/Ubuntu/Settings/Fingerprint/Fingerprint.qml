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
import Ubuntu.Components 1.2

Page {
    id: root
    title: i18n.tr("Fingerprint ID")

    // This signal indicates that the user has requested that she to set a
    // passcode.
    signal requestPasscode()

    property boolean passcodeSet: false
    property number fingerprintCount: 0

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
        anchors.fill: parent
        contentHeight: contentItem.childrenRect.height
        boundsBehavior: (contentHeight > root.height) ?
                            Flickable.DragAndOvershootBounds :
                            Flickable.StopAtBounds

        Column {
            spacing: units.gu(1)

            Column {
                id: setupPasscode
                anchors { left: parent.left; right: parent.right }
                visible: false
                Label {
                    anchors { left: parent.left; right: parent.right }
                    text: i18n.tr("You must set a passcode before using fingerprint ID")
                }

                Button {
                    text: i18n.tr("Set Passcode…")
                    onClicked: root.requestPasscode()
                }
            }

            Column {
                id: setupFingerprint
                anchors { left: parent.left; right: parent.right }
                property boolean enabled: true

                Label {
                    // TRANSLATORS: As in "One fingerprint registered"
                    property string one: i18n.tr("One")
                    // TRANSLATORS: As in "Two fingerprints registered"
                    property string two: i18n.tr("Two")
                    // TRANSLATORS: As in "Three fingerprints registered"
                    property string three: i18n.tr("Three")
                    // TRANSLATORS: As in "Four fingerprints registered"
                    property string four: i18n.tr("Four")
                    // TRANSLATORS: As in "Five fingerprints registered"
                    property string five: i18n.tr("Five")
                    // TRANSLATORS: As in "Six fingerprints registered"
                    property string six: i18n.tr("Six")
                    // TRANSLATORS: As in "Seven fingerprints registered"
                    property string seven: i18n.tr("Seven")
                    // TRANSLATORS: As in "Eight fingerprints registered"
                    property string eight: i18n.tr("Eight")
                    // TRANSLATORS: As in "Nine fingerprints registered"
                    property string nine: i18n.tr("Nine")

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
                            return i18n.tr("No fingerprints registered.");
                        } else {
                            // TRANSLATORS: %1 is the number of fingerprints registered.
                            return i18n.tr("%1 fingerprint registered.",
                                           "%1 fingerprints registered.",
                                           fpc).arg(getNaturalNumber(fpc));
                        }
                    }
                }
            }
        }
    }
}
