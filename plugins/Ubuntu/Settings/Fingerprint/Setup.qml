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

import Biometryd 0.0
import QtGraphicalEffects 1.0
import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Settings.Fingerprint 0.1

Page {
    id: root

    objectName: "fingerprintSetupPage"

    signal enroll()
    signal cancel()

    function enrollmentFailed(error) {
        root.state = "failed";
    }

    function enrollmentCompleted() {
        root.state = "done";
    }

    function enrollmentProgressed(progress, hints) {
        var fingerPresent = !!hints[FingerprintReader.isFingerPresent];
        shapeDown.visible = fingerPresent;
        shapeUp.visible = !fingerPresent;

        root.state = "reading";
        imageDefault.masks = hints[FingerprintReader.masks];
        statusLabel.setText(i18n.dtr("ubuntu-settings-components",
                            "Lift and press your finger again."));
    }

    states: [
        State {
            name: ""
            StateChangeScript {
                script: statusLabel.setText(statusLabel.initialText)
            }
        },
        State {
            name: "reading"
            StateChangeScript {
                script: statusLabel.setText(
                    i18n.dtr("ubuntu-settings-components",
                             "Lift and press your finger again.")
                )
            }

        },
        State {
            name: "longer"
            StateChangeScript {
                script: statusLabel.setText(
                    i18n.dtr("ubuntu-settings-components",
                             "Keep your finger on the button for longer.")
                )
            }
        },
        State {
            name: "failed"
            PropertyChanges {
                target: imageDefault
                visible: false
            }
            PropertyChanges {
                target: imageFailed
                visible: true
            }
            PropertyChanges {
                target: cancelButton
                text: i18n.dtr("ubuntu-settings-components", "Back");
            }
            PropertyChanges {
                target: doneButton
                visible: false
            }
            StateChangeScript {
                script: statusLabel.setText(
                    i18n.dtr("ubuntu-settings-components",
                             "Sorry, the reader doesn’t seem to be working.")
                )
            }
        },
        State {
            name: "done"
            PropertyChanges {
                target: imageDefault
                visible: false
            }
            PropertyChanges {
                target: imageDone
                visible: true
            }
            PropertyChanges {
                target: cancelButton
                visible: false
            }
            StateChangeScript {
                script: statusLabel.setText(
                    i18n.dtr("ubuntu-settings-components", "All done!")
                )
            }
            PropertyChanges {
                target: doneButton
                enabled: true
                text: i18n.dtr("ubuntu-settings-components", "OK")
            }
        }
    ]

    header: PageHeader {
        visible: false
    }

    Item {
        anchors.fill: parent

        Item {
            id: readerPositioner

            anchors {
                bottom: actions.top
                bottomMargin: units.gu(25.5)
                left: parent.left
                leftMargin: units.gu(12)
                right: parent.right
                rightMargin: units.gu(12)
                top: parent.top
                topMargin: units.gu(27.5)
            }

            Item {
                width: units.gu(26)
                height: units.gu(29)

                BorderImage {
                    id: shapeDown
                    objectName: "fingerprintDownVisual"
                    visible: false
                    anchors.fill: parent
                    source: "qrc:/assets/shape-down.sci"
                }

                BorderImage {
                    id: shapeUp
                    objectName: "fingerprintUpVisual"
                    anchors {
                        fill: parent
                        margins: units.gu(0.4)
                    }
                    source: "qrc:/assets/shape-up.sci"
                }

                Item {
                    id: imageContainer
                    anchors.centerIn: parent
                    width: imageDefault.implicitWidth
                    height: imageDefault.implicitHeight


                    // Default image.
                    FingerprintVisual {
                        id: imageDefault
                        objectName: "fingerprintDefaultVisual"
                        anchors.centerIn: parent
                    }

                    // Failed image.
                    Image {
                        id: imageFailed
                        objectName: "fingerprintFailedVisual"
                        anchors.fill: parent
                        asynchronous: true
                        fillMode: Image.Pad
                        sourceSize.width: parent.width
                        sourceSize.height: parent.height
                        source: "qrc:/assets/fingerprint_failed.svg"
                        visible: false
                    }

                    // Done image.
                    Image {
                        id: imageDone
                        objectName: "fingerprintDoneVisual"
                        anchors.fill: parent
                        asynchronous: true
                        fillMode: Image.Pad
                        sourceSize.width: parent.width
                        sourceSize.height: parent.height
                        source: "qrc:/assets/fingerprint_done.svg"
                        visible: false
                    }
                }
            }
        }

        StatusLabel {
            id: statusLabel
            anchors {
                left: parent.left
                leftMargin: units.gu(2.9)
                right: parent.right
                rightMargin: units.gu(2.9)
                top: parent.top
                topMargin: units.gu(4.9)
            }
            initialText: i18n.dtr("ubuntu-settings-components",
                                  "Place your finger on the home button.")
            objectName: "fingerprintStatusLabel"
        }

        Rectangle {
            id: actions

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            color: "#FFF7F7F7"
            height: units.gu(4.9)

            AbstractButton {
                id: cancelButton
                property alias text: cancelButtonText.text
                objectName: "fingerprintSetupCancelButton"
                anchors {
                    left: parent.left
                    leftMargin: units.gu(3)
                    verticalCenter: parent.verticalCenter
                }
                height: parent.height
                width: units.gu(10)
                onClicked: {
                    root.cancel();
                    pageStack.pop();
                }

                Label {
                    id: cancelButtonText
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n.dtr("ubuntu-settings-components", "Cancel")
                }
            }

            AbstractButton {
                id: doneButton
                property alias text: doneButtonText.text
                objectName: "fingerprintSetupDoneButton"
                anchors {
                    right: parent.right
                    rightMargin: units.gu(3)
                    verticalCenter: parent.verticalCenter
                }
                enabled: false
                height: parent.height
                width: units.gu(10)
                onClicked: pageStack.pop()

                Label {
                    id: doneButtonText
                    anchors {
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                    }
                    font.bold: parent.enabled
                    text: i18n.dtr("ubuntu-settings-components", "Next")
                }
            }
        }
    }
}
