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
        // shapeDown.visible = fingerPresent;
        // shapeUp.visible = !fingerPresent;

        root.state = "reading";
        imageDefault.masks = hints[FingerprintReader.masks];
        progressLabel.progress = 100 * progress;
        directionContainer.direction = hints[FingerprintReader.suggestedNextDirection] || FingerprintReader.NotAvailable;
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
            PropertyChanges {
                target: imageDefault
                opacity: 1
            }
            PropertyChanges {
                target: progressLabel
                opacity: 1
            }
        },
        State {
            name: "longer"
            StateChangeScript {
                script: statusLabel.setText(
                    i18n.dtr("ubuntu-settings-components",
                             "Keep your finger on the reader for longer.")
                )
            }
        },
        State {
            name: "failed"
            PropertyChanges {
                target: imageDefault
                opacity: 0
            }
            PropertyChanges {
                target: imageFailed
                opacity: 1
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
                             "Sorry, the reader doesn’t seem to be working."),
                    true // No animation
                )
            }
            StateChangeScript {
                script: imageFailed.start()
            }
            PropertyChanges {
                target: directionContainer
                opacity: 0
            }
        },
        State {
            name: "done"
            PropertyChanges {
                target: imageDefault
                opacity: 0
            }
            PropertyChanges {
                target: imageDone
                opacity: 1
            }
            PropertyChanges {
                target: cancelButton
                visible: false
            }
            StateChangeScript {
                script: statusLabel.setText(
                    i18n.dtr("ubuntu-settings-components", "All done!"),
                    true // No animation
                )
            }
            PropertyChanges {
                target: doneButton
                enabled: true
                text: i18n.dtr("ubuntu-settings-components", "OK")
            }
            StateChangeScript {
                script: imageDone.start()
            }
            PropertyChanges {
                target: directionContainer
                opacity: 0
            }
        }
    ]

    header: PageHeader {
        visible: false
    }

    Item {
        anchors.fill: parent

        Item {
            id: fingerprintBox
            anchors.centerIn: parent
            width: units.gu(26)
            height: units.gu(29)

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

                    Behavior on opacity { UbuntuNumberAnimation {
                        duration: UbuntuAnimation.SlowDuration
                        easing: UbuntuAnimation.StandardEasing
                    }}
                }

                // Failed image.
                CircularSegment {
                    id: imageFailed
                    objectName: "fingerprintFailedVisual"
                    opacity: 0
                    color: "#ED3146"
                    width: directionContainer.width - units.dp(3)

                    anchors.centerIn: parent

                    function start () {
                        failAngstopAnim.start();
                        failThichAnim.start();
                    }

                    NumberAnimation on angleStop {
                        id: failAngstopAnim
                        running: false
                        from: 0
                        to: 360
                        duration: UbuntuAnimation.SlowDuration
                        easing: UbuntuAnimation.StandardEasing
                    }

                    NumberAnimation on thickness {
                        id: failThichAnim
                        running: false
                        from: 0
                        to: units.dp(3)
                        duration: UbuntuAnimation.SlowDuration
                        easing: UbuntuAnimation.StandardEasing
                    }

                    Icon {
                        name: "close"
                        color: "#ED3146"
                        width: units.gu(18)
                        anchors.centerIn: parent
                    }

                    Behavior on opacity { UbuntuNumberAnimation {
                        duration: UbuntuAnimation.SlowDuration
                        easing: UbuntuAnimation.StandardEasing
                    }}
                }

                // Done image.
                CircularSegment {
                    id: imageDone
                    objectName: "fingerprintDoneVisual"
                    opacity: 0
                    width: directionContainer.width - units.dp(3)

                    anchors.centerIn: parent

                    function start () {
                        angstopAnim.start();
                        thickAnim.start();
                    }

                    NumberAnimation on angleStop {
                        id: angstopAnim
                        running: false
                        from: 0
                        to: 360
                        duration: UbuntuAnimation.SlowDuration
                        easing: UbuntuAnimation.StandardEasing
                    }

                    NumberAnimation on thickness {
                        id: thickAnim
                        running: false
                        from: 0
                        to: units.dp(3)
                        duration: UbuntuAnimation.SlowDuration
                        easing: UbuntuAnimation.StandardEasing
                    }

                    Icon {
                        name: "tick"
                        color: "#3EB34F"
                        width: units.gu(18)
                        anchors.centerIn: parent
                    }

                    Behavior on opacity { UbuntuNumberAnimation {
                        duration: UbuntuAnimation.SlowDuration
                        easing: UbuntuAnimation.StandardEasing
                    }}
                }

                DirectionVisual {
                    id: directionContainer
                    objectName: "fingerprintDirectionVisual"
                    anchors.centerIn: parent

                    width: Math.sqrt(
                        imageContainer.width*imageContainer.width
                        + imageContainer.height*imageContainer.height
                    )
                    height: width
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
                topMargin: units.gu(5)
            }
            initialText: i18n.dtr("ubuntu-settings-components",
                                  "Place your finger on the home button.")
            objectName: "fingerprintStatusLabel"
        }


        Label {
            id: progressLabel
            objectName: "fingerprintProgressLabel"
            property int progress: 0
            anchors {
                top: fingerprintBox.bottom
                topMargin: units.gu(1.5)
                horizontalCenter: parent.horizontalCenter
            }
            text: i18n.dtr("ubuntu-settings-components", "%1%").arg((progress).toFixed());
            opacity: 0
            horizontalAlignment: Text.AlignHCenter
            fontSize: "large"
            color: theme.palette.normal.backgroundTertiaryText

            Behavior on opacity { UbuntuNumberAnimation {} }
            Behavior on progress {
                NumberAnimation {
                    duration: UbuntuAnimation.SlowDuration
                    easing: UbuntuAnimation.StandardEasing
                }
            }
        }

        Rectangle {
            id: actions

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            // Color and height values are copied from the Wizard.
            color: "#f5f5f5"
            height: units.gu(5)

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
