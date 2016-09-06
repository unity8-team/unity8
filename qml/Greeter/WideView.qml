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
import "." 0.1

FocusScope {
    id: root
    focus: true

    property alias background: lockscreen.background
    property alias backgroundTopMargin: lockscreen.backgroundTopMargin
    property alias hasCustomBackground: lockscreen.hasCustomBackground
    property alias dragHandleLeftMargin: lockscreen.dragHandleLeftMargin
    property alias infographicModel: infographics.model
    property real launcherOffset // unused
    property real launcherLockedWidth
    property alias currentIndex: lockscreen.currentIndex
    property alias delayMinutes: lockscreen.delayMinutes
    property alias alphanumeric: lockscreen.alphanumeric
    property alias locked: lockscreen.locked
    property alias sessionToStart: lockscreen.currentSession
    property alias waiting: lockscreen.waiting
    property alias userModel: lockscreen.userModel
    property bool oskEnabled

    readonly property bool animating: false
    readonly property bool fullyShown: lockscreen.shown
    readonly property bool required: lockscreen.required
    readonly property int supportedOrientations: Qt.PortraitOrientation |
                                                 Qt.LandscapeOrientation |
                                                 Qt.InvertedPortraitOrientation |
                                                 Qt.InvertedLandscapeOrientation

    // so that it can be replaced in tests with a mock object
    property var inputMethod: Qt.inputMethod

    signal selected(int index)
    signal responded(string response)
    signal tease()
    signal emergencyCall() // unused

    function notifyAuthenticationFailed() {
        lockscreen.notifyAuthenticationFailed();
    }

    function reset(forceShow) {
        lockscreen.reset();
    }

    function showMessage(html) {
        lockscreen.showMessage(html);
    }

    function showPrompt(text, isSecret, isDefaultPrompt) {
        lockscreen.showPrompt(text, isSecret, isDefaultPrompt);
    }

    function showErrorMessage(msg) {
        // Unused, only for optional coverPage message when prompt is covered,
        // but we always show prompt, so we don't need this.
    }

    function tryToUnlock(toTheRight) {
        lockscreen.tryToUnlock();
        return false;
    }

    QtObject {
        id: d
        property bool landscape: root.width > root.height
    }

    function hide() {
        lockscreen.hide();
    }

    function notifyAuthenticationSucceeded(showFakePassword) {
        lockscreen.notifyAuthenticationSucceeded(showFakePassword);
    }

    LoginPage {
        id: lockscreen
        objectName: "lockscreen"
        anchors.fill: parent

        property real layoutWidth: width - root.launcherLockedWidth
        promptHorizontalCenterOffset: root.launcherLockedWidth +
                                      (d.landscape ? layoutWidth / 4 : layoutWidth / 2)
        promptVerticalCenterOffset: d.landscape && !root.oskEnabled ?
                                    height / 2 :
                                    Math.min(units.gu(21) + promptHeight / 2,
                                             height / 2 - promptHeight / 2 - units.gu(1))
        inputMethod: root.inputMethod

        onEmergencyCall: root.emergencyCall()
        onSelected: root.selected(index)
        onResponded: root.responded(response)
        onClicked: root.tease()

        Infographics {
            id: infographics
            objectName: "infographics"

            readonly property real promptBottom: lockscreen.promptVerticalCenterOffset + lockscreen.promptHeight / 2

            width: Math.min(units.gu(50),
                            d.landscape ? 0.5 * parent.layoutWidth : 0.64 * (lockscreen.height - promptBottom),
                            parent.layoutWidth,
                            parent.height)
            height: width

            useColor: !root.hasCustomBackground

            anchors {
                horizontalCenter: parent.right
                horizontalCenterOffset: root.launcherLockedWidth - lockscreen.promptHorizontalCenterOffset

                verticalCenter: parent.verticalCenter
                verticalCenterOffset: d.landscape ? 0 : promptBottom / 2
            }
        }
    }
}
