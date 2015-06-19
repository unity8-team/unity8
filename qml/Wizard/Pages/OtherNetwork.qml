/*
 * Copyright 2013 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1
import Ubuntu.SystemSettings.Wifi 1.0
import QMenuModel 0.1

Component {
    Dialog {
        z:  10
        id: otherNetworkDialog
        objectName: "otherNetworkDialog"
        anchorToKeyboard: true
        property color originalBackground
        property color originalBackgroundText

        function settingsValid() {
            if(networkname.length == 0) {
                return false;
            }
            if(securityList.selectedIndex == 0) {
                return true
            }
            if(securityList.selectedIndex == 1) {
                return password.length >= 8
            }
            // WEP
            return password.length === 5  ||
                   password.length === 10 ||
                   password.length === 13 ||
                   password.length === 26;
        }

        title: i18n.tr("Connect to Hidden Network")
        text: feedback.enabled ? feedback.text : "";

        Common {
            id: common
        }

        states: [
            State {
                name: "CONNECTING"
                PropertyChanges {
                    target: connectAction
                    enabled: false
                }
                PropertyChanges {
                    target: connectButtonIndicator
                    running: true
                }
                PropertyChanges {
                    target: passwordVisibleSwitch
                    enabled: false
                }
                PropertyChanges {
                    target: passwordVisibleLabel
                    opacity: 0.5
                }
                PropertyChanges {
                    target: password
                    enabled: false
                }
                PropertyChanges {
                    target: passwordListLabel
                    opacity: 0.5
                }
                PropertyChanges {
                    target: securityList
                    enabled: false
                    opacity: 0.5
                }
                PropertyChanges {
                    target: securityListLabel
                    opacity: 0.5
                }
                PropertyChanges {
                    target: networkname
                    enabled: false
                }
                PropertyChanges {
                    target: networknameLabel
                    opacity: 0.5
                }
                PropertyChanges {
                    target: feedback
                    enabled: true
                }
            },
            State {
                name: "FAILED"
                PropertyChanges {
                    target: feedback
                    enabled: true
                }
            },
            State {
                name: "SUCCEEDED"
                PropertyChanges {
                    target: successIndicator
                    running: true
                }
                PropertyChanges {
                    target: cancelButton
                    enabled: false
                }
                PropertyChanges {
                    target: connectAction
                    enabled: false
                }
            }
        ]

        Label {
            property bool enabled: false
            id: feedback
            horizontalAlignment: Text.AlignHCenter
            height: contentHeight
            wrapMode: Text.Wrap
            visible: false
        }

        Label {
            id: networknameLabel
            text : i18n.tr("Network name")
            objectName: "networknameLabel"
            fontSize: "medium"
            font.bold: true
            elide: Text.ElideRight
        }

        TextField {
            id : networkname
            objectName: "networkname"
            inputMethodHints: Qt.ImhNoPredictiveText
            Component.onCompleted: forceActiveFocus()
        }

        Label {
            id: securityListLabel
            text : i18n.tr("Security")
            objectName: "securityListLabel"
            fontSize: "medium"
            font.bold: true
            elide: Text.ElideRight
        }

        ListItem.ItemSelector {
            id: securityList
            objectName: "securityList"
            model: [i18n.tr("None"),                 // index: 0
                    i18n.tr("WPA & WPA2 Personal"),  // index: 1
                    i18n.tr("WEP"),                  // index: 2
                    ]
        }

        Label {
            id: passwordListLabel
            text : i18n.tr("Password")
            objectName: "passwordListLabel"
            fontSize: "medium"
            font.bold: true
            elide: Text.ElideRight
            visible: securityList.selectedIndex !== 0
        }

        TextField {
            id : password
            objectName: "password"
            visible: securityList.selectedIndex !== 0
            echoMode: passwordVisibleSwitch.checked ?
                TextInput.Normal : TextInput.Password
            inputMethodHints: Qt.ImhNoPredictiveText
            onAccepted: {
                connectAction.trigger();
            }
        }

        Row {
            id: passwordVisiblityRow
            layoutDirection: Qt.LeftToRight
            spacing: units.gu(2)
            visible: securityList.selectedIndex !== 0

            CheckBox {
                id: passwordVisibleSwitch
                activeFocusOnPress: false
            }

            Label {
                id: passwordVisibleLabel
                text : i18n.tr("Show password")
                objectName: "passwordVisibleLabel"
                fontSize: "medium"
                elide: Text.ElideRight
                height: passwordVisibleSwitch.height
                verticalAlignment: Text.AlignVCenter
                MouseArea {
                    anchors {
                        fill: parent
                    }
                    onClicked: {
                        passwordVisibleSwitch.checked =
                            !passwordVisibleSwitch.checked
                    }
                }
            }
        }

        RowLayout {
            id: buttonRow
            anchors {
                left: parent.left
                right: parent.right
            }
            spacing: units.gu(2)
            height: cancelButton.height

            Button {
                id: cancelButton
                objectName: "cancel"
                Layout.fillWidth: true
                text: i18n.tr("Cancel")
                onClicked: {
                    PopupUtils.close(otherNetworkDialog);

                    // If this dialog created the connection,
                    // disconnect the device
                    if (otherNetworkDialog.state === "CONNECTING") {
                        DbusHelper.forgetActiveDevice();
                    }
                }
            }

            Button {
                id: connectButton
                objectName: "connect"
                Layout.fillWidth: true
                text: i18n.tr("Connect")
                enabled: connectAction.enabled
                action: connectAction
                color: "green"
                Icon {
                    height: parent.height - units.gu(1.5)
                    width: parent.height - units.gu(1.5)
                    anchors {
                        centerIn: parent
                    }
                    name: "tick"
                    color: "green"
                    visible: successIndicator.running
                }
                ActivityIndicator {
                    id: connectButtonIndicator
                    running: false
                    visible: running
                    height: parent.height - units.gu(1.5)
                    anchors {
                        centerIn: parent
                    }
                }
            }
        }

        Action {
            id: connectAction
            enabled: settingsValid()
            onTriggered: {
                DbusHelper.connect(
                    networkname.text,
                    securityList.selectedIndex,
                    password.text);
                otherNetworkDialog.state = "CONNECTING";
            }
        }

        /* Timer that shows a tick in the connect button once we have
        successfully connected. */
        Timer {
            id: successIndicator
            interval: 2000
            running: false
            repeat: false
            onTriggered: PopupUtils.close(otherNetworkDialog)
        }

        Connections {
            target: DbusHelper
            onDeviceStateChanged: {
                if (otherNetworkDialog.state === "FAILED") {
                    /* Disconnect the device if it tries to reconnect after a
                    connection failure */
                    if (newState === 40) { // 40 = NM_DEVICE_STATE_PREPARE
                        DbusHelper.forgetActiveDevice();
                    }
                }

                /* We will only consider these cases if we are in
                the CONNECTING state. This means that this Dialog will not
                react to what other NetworkManager consumers do.
                */
                if (otherNetworkDialog.state === "CONNECTING") {
                    switch (newState) {
                        case 120:
                            feedback.text = common.reasonToString(reason);
                            otherNetworkDialog.state = "FAILED";
                            break;
                        case 100:
                            /* connection succeeded only if it was us that
                            created it */
                            otherNetworkDialog.state = "SUCCEEDED";
                            break;
                    }
                }
            }
        }

        Component.onCompleted: {
            originalBackground = Theme.palette.selected.background
            originalBackgroundText = Theme.palette.selected.backgroundText
            Theme.palette.selected.background = Qt.rgba(0, 0, 0, 0.05)
            Theme.palette.selected.backgroundText = UbuntuColors.darkGrey
        }

        Component.onDestruction: {
            Theme.palette.selected.background = originalBackground
            Theme.palette.selected.backgroundText = originalBackgroundText
        }
    }

}


