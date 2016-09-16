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
import QtQuick.Window 2.2
import Ubuntu.Components 1.3

FocusScope {
    id: root

    property alias dragHandleLeftMargin: coverPage.dragHandleLeftMargin
    property alias launcherOffset: coverPage.launcherOffset
    property real launcherLockedWidth // unused
    property alias currentIndex: lockscreen.currentIndex
    property alias delayMinutes: lockscreen.delayMinutes
    property alias backgroundTopMargin: lockscreen.backgroundTopMargin
    property alias background: lockscreen.background
    property alias hasCustomBackground: lockscreen.hasCustomBackground
    property alias locked: lockscreen.locked
    property alias alphanumeric: lockscreen.alphanumeric
    property alias userModel: lockscreen.userModel
    property alias infographicModel: coverPage.infographicModel
    property alias sessionToStart: lockscreen.currentSession
    property alias waiting: lockscreen.waiting
    property bool oskEnabled
    readonly property bool fullyShown: coverPage.showProgress === 1 || lockscreen.shown
    readonly property bool required: coverPage.required || lockscreen.required
    readonly property bool animating: coverPage.showAnimation.running || coverPage.hideAnimation.running
    readonly property int supportedOrientations: Qt.PortraitOrientation |
                                                 Qt.InvertedPortraitOrientation

    // so that it can be replaced in tests with a mock object
    property var inputMethod: Qt.inputMethod

    signal selected(int index)
    signal responded(string response)
    signal tease()
    signal emergencyCall()

    function showMessage(html) {
        lockscreen.showMessage(html);
    }

    function showPrompt(text, isSecret, isDefaultPrompt) {
        lockscreen.showPrompt(text, isSecret, isDefaultPrompt);
    }

    function hide() {
        lockscreen.hide();
        coverPage.hide();
    }

    function notifyAuthenticationSucceeded(showFakePassword) {
        lockscreen.notifyAuthenticationSucceeded(showFakePassword);
    }

    function notifyAuthenticationFailed() {
        lockscreen.notifyAuthenticationFailed();
    }

    function showErrorMessage(msg) {
        // Only useful when coverPage is covering lockscreen, so only send there
        coverPage.showErrorMessage(msg);
    }

    function reset(forceShow) {
        lockscreen.reset();
        if (forceShow) {
            coverPage.show();
        }
    }

    function tryToUnlock(toTheRight) {
        var coverChanged = coverPage.shown;
        lockscreen.maybeShow();
        if (toTheRight) {
            coverPage.hideRight();
        } else {
            coverPage.hide();
        }
        return coverChanged;
    }

    onLockedChanged: {
        if (locked || userModel.count > 1) {
            lockscreen.maybeShow();
        } else {
            lockscreen.hide();
        }
    }

    LoginPage {
        id: lockscreen
        objectName: "lockscreen"
        anchors.fill: parent
        shown: false

        hasCancel: true
        covered: coverPage.shown
        promptHorizontalCenterOffset: width / 2
        promptVerticalCenterOffset: Math.min(units.gu(14) + promptHeight / 2,
                                             height / 2 - promptHeight / 2 - units.gu(1) - bottomBar.height)
        inputMethod: root.inputMethod
        dragHandleLeftMargin: root.dragHandleLeftMargin

        onCancel: coverPage.show()
        onEmergencyCall: root.emergencyCall()
        onSelected: root.selected(index)
        onResponded: root.responded(response)
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: coverPage.showProgress * 0.8
    }

    CoverPage {
        id: coverPage
        objectName: "coverPage"
        height: parent.height
        width: parent.width

        background: root.background
        backgroundTopMargin: root.backgroundTopMargin
        hasCustomBackground: root.hasCustomBackground
        draggable: !root.waiting

        onTease: root.tease()
        onClicked: hide()

        onShowProgressChanged: {
            if (showProgress === 1) {
                lockscreen.reset();
            } else if (showProgress === 0) {
                lockscreen.tryToUnlock();
            }
        }
    }

    StyledItem {
        id: bottomBar
        visible: lockscreen.shown
        height: units.gu(4)

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.bottom
        anchors.topMargin: - height * (1 - coverPage.showProgress)
                           - (inputMethod && inputMethod.visible ?
                              inputMethod.keyboardRectangle.height : 0)

        Rectangle {
            color: UbuntuColors.porcelain // matches OSK background
            anchors.fill: parent
        }

        Label {
            text: i18n.tr("Cancel")
            anchors.left: parent.left
            anchors.leftMargin: units.gu(2)
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            verticalAlignment: Text.AlignVCenter
            font.weight: Font.Light
            fontSize: "small"
            color: UbuntuColors.slate

            AbstractButton {
                anchors.fill: parent
                anchors.leftMargin: -units.gu(2)
                anchors.rightMargin: -units.gu(2)
                onClicked: coverPage.show()
            }
        }

        Label {
            objectName: "emergencyCallLabel"
            text: callManager.hasCalls ? i18n.tr("Return to Call") : i18n.tr("Emergency")
            anchors.right: parent.right
            anchors.rightMargin: units.gu(2)
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            verticalAlignment: Text.AlignVCenter
            font.weight: Font.Light
            fontSize: "small"
            color: UbuntuColors.slate
            // TODO: uncomment once bug 1616538 is fixed
            // visible: telepathyHelper.ready && telepathyHelper.emergencyCallsAvailable
            enabled: visible

            AbstractButton {
                anchors.fill: parent
                anchors.leftMargin: -units.gu(2)
                anchors.rightMargin: -units.gu(2)
                onClicked: root.emergencyCall()
            }
        }
    }

    // FIXME: It's difficult to keep something tied closely to the OSK (bug
    //        1616163).  But as a hack to avoid the background peeking out,
    //        we add an extra Rectangle that just serves to hide the background
    //        during OSK animations.
    Rectangle {
        visible: bottomBar.visible
        height: inputMethod && inputMethod.visible ?
                inputMethod.keyboardRectangle.height : 0
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        color: UbuntuColors.porcelain
    }
}
