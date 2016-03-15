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

Page {
    id: root

    states: [
        State {
            name: "reading"
            PropertyChanges {
                target: imageDefault
                opacity: 1
            }
        },
        State {
            name: "longer"
            extend: "reading"
            PropertyChanges {
                target: statusLabel
                text: i18n.dtr("ubuntu-settings-components", "Keep your finger on the button for longer.")
            }
        },
        State {
            name: "again"
            extend: "reading"
            PropertyChanges {
                target: statusLabel
                text: i18n.dtr("ubuntu-settings-components", "Lift and press your finger again.")
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
                target: statusLabel
                text: i18n.dtr("ubuntu-settings-components", "Sorry, the reader doesn’t seem to be working.")
            }
        },
        State {
            name: "ok"
            PropertyChanges {
                target: imageDefault
                visible: false
            }
            PropertyChanges {
                target: imageDone
                visible: true
            }
            PropertyChanges {
                target: statusLabel
                text: i18n.dtr("ubuntu-settings-components", "All done!")
            }
            PropertyChanges {
                target: doneButton
                enabled: true
            }
        }
    ]

    header: PageHeader {
        leadingActionBar.actions: []
        visible: false
    }

    Item {
        anchors {
            fill: parent
            margins: units.gu(2)
        }

        Item {
            id: readerSurface

            anchors {
                top: statusLabel.bottom
                topMargin: units.gu(5)
                bottom: actions.top
                bottomMargin: units.gu(5)
                left: parent.left
                leftMargin: units.gu(2)
                right: parent.right
                rightMargin: units.gu(2)
                horizontalCenter: parent.horizontalCenter
            }

            // Default image.
            Image {
                id: imageDefault
                opacity: 0.2
                asynchronous: true
                anchors.horizontalCenter: parent.horizontalCenter
                fillMode: Image.PreserveAspectFit
                sourceSize.height: parent.height
                sourceSize.width: parent.width
                source: "fingerprint.svg"
            }

            // Failed image.
            Image {
                id: imageFailed
                asynchronous: true
                visible: false
                anchors.horizontalCenter: parent.horizontalCenter
                fillMode: Image.PreserveAspectFit
                sourceSize.height: parent.height
                sourceSize.width: parent.width
                source: "fingerprint_failed.svg"
            }

            // Done image.
            Image {
                id: imageDone
                asynchronous: true
                visible: false
                anchors.horizontalCenter: parent.horizontalCenter
                fillMode: Image.PreserveAspectFit
                sourceSize.height: parent.height
                sourceSize.width: parent.width
                source: "fingerprint_done.svg"
            }

            MouseArea {
                anchors.fill: parent
                onPressed: root.state = "longer"
                onReleased: root.state = "again"
            }
        }

        Label {
            id: statusLabel
            anchors { left: parent.left; right: parent.right }
            horizontalAlignment: Text.AlignHCenter
            height: units.gu(4)
            wrapMode: Text.WordWrap
            fontSize: "large"
            text: i18n.dtr("ubuntu-settings-components", "Place your finger on the home button.")
        }

        RowLayout {
            id: actions
            spacing: units.gu(2)
            anchors {
                left: parent.left;
                right: parent.right
                bottom: parent.bottom
            }

            Button {
                id: cancelButton
                text: i18n.dtr("ubuntu-settings-components", "Cancel")
                Layout.fillWidth: true
                onClicked: pageStack.pop()
            }

            Button {
                id: doneButton
                enabled: false
                color: UbuntuColors.green
                text: i18n.dtr("ubuntu-settings-components", "Done")
                Layout.fillWidth: true
            }
        }

    }
}
