/*
 * Copyright (C) 2015-2016 Canonical, Ltd.
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

import QtQuick 2.4
import Ubuntu.Components 1.3
import "../Components"

Showable {
    id: root

    property alias background: wallpaper.source
    property real backgroundTopMargin
    property bool hasCustomBackground
    property alias locked: loginList.locked
    property alias waiting: loginList.waiting
    property bool alphanumeric: true
    property alias delayMinutes: delayedLockscreen.delayMinutes
    property bool hasCancel
    property bool covered
    property alias userModel: loginList.model
    property alias currentIndex: loginList.currentIndex
    property real promptHorizontalCenterOffset
    property real promptVerticalCenterOffset
    property real dragHandleLeftMargin
    property alias currentSession: loginList.currentSession
    readonly property alias promptHeight: loginList.highlightedHeight

    // so that it can be replaced in tests with a mock object
    property var inputMethod: Qt.inputMethod

    signal cancel()
    signal emergencyCall()
    signal selected(int index)
    signal responded(string response)
    signal clicked()

    function showMessage(html) {
        loginList.showMessage(html);
    }

    function showPrompt(text, isSecret, isDefaultPrompt) {
        loginList.showPrompt(text, isSecret, isDefaultPrompt);
    }

    function notifyAuthenticationSucceeded(showFakePassword) {
        if (showFakePassword) {
            loginList.showFakePassword();
        }
    }

    function notifyAuthenticationFailed() {
        loginList.showError();
    }

    function reset() {
        loginList.reset();
    }

    function tryToUnlock() {
        loginList.tryToUnlock();
    }

    showAnimation: StandardAnimation { property: "opacity"; to: 1 }
    hideAnimation: StandardAnimation { property: "opacity"; to: 0 }

    Wallpaper {
        id: wallpaper
        anchors.fill: parent
        anchors.topMargin: root.backgroundTopMargin
    }

    // Darken background when custom background is used to see our overlays
    Rectangle {
        objectName: "lockscreenShade"
        anchors.fill: parent
        color: "black"
        opacity: root.hasCustomBackground ? 0.4 : 0
    }

    MouseArea {
        anchors.fill: parent
        anchors.leftMargin: root.dragHandleLeftMargin
        onClicked: root.clicked()
    }

    LoginList {
        id: loginList
        objectName: "loginList"
        z: 1 // place above any custom items (like infographics)

        anchors {
            horizontalCenter: parent.left
            horizontalCenterOffset: root.promptHorizontalCenterOffset
            top: parent.top
            bottom: parent.bottom
        }
        width: units.gu(40)

        boxVerticalOffset: root.promptVerticalCenterOffset - highlightedHeight/2

        enabled: !root.covered && visible
        visible: !delayedLockscreen.visible
        alphanumeric: root.alphanumeric

        onSelected: if (enabled) root.selected(index)
        onResponded: root.responded(response)
        onSessionChooserButtonClicked: parent.state = "SessionsList"

        Keys.forwardTo: [sessionChooserLoader.item]
    }

    Loader {
        id: sessionChooserLoader
        z: 1

        height: loginList.height
        width: loginList.width
        anchors {
            left: parent.left
            leftMargin: Math.min(parent.width * 0.16, units.gu(20))
            top: parent.top
        }

        active: false

        onLoaded: sessionChooserLoader.item.forceActiveFocus()
        Binding {
            target: sessionChooserLoader.item
            property: "initiallySelectedSession"
            value: loginList.currentSession
        }

        Connections {
            target: sessionChooserLoader.item
            onSessionSelected: loginList.currentSession = sessionKey
            onShowLoginList: {
                root.state = "LoginList"
                loginList.passwordInput.forceActiveFocus();
            }
            ignoreUnknownSignals: true
        }
    }

    states: [
        State {
            name: "SessionsList"
            PropertyChanges { target: loginList; opacity: 0 }
            PropertyChanges { target: sessionChooserLoader;
                              active: true;
                              opacity: 1
                              source: "SessionsList.qml"
                            }
        },

        State {
            name: "LoginList"
            PropertyChanges { target: loginList; opacity: 1 }
            PropertyChanges { target: sessionChooserLoader;
                              active: false;
                              opacity: 0
                              source: "";
                            }
        }
    ]

    transitions: [
        Transition {
            from: "*"
            to: "*"
            UbuntuNumberAnimation {
                property: "opacity";
            }
        }
    ]

    DelayedLockscreen {
        id: delayedLockscreen
        objectName: "delayedLockscreen"
        anchors.fill: parent
        visible: delayMinutes > 0
        alphaNumeric: root.alphanumeric
    }

    function maybeShow() {
        if (root.locked && !shown) {
            showNow();
        }
    }
}
