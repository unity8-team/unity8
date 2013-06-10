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
import Ubuntu.Application 0.1
import "../../../Stages"
import "../../../Components"
import "tst_StageManager"

Item {
    id: root
    width: units.gu(40)
    height: units.gu(72)

    property var applicationManager: ApplicationManagerWrapper {}

    Rectangle { //fake background
        anchors.fill: parent
        color: "black"
        visible: stageManager.needUnderlay
    }

    StageManager {
        id: stageManager

        anchors.fill: parent

        applicationManager: root.applicationManager
        leftSwipePosition: 0
        panelHeight: units.gu(3) + units.dp(2)
        edgeHandleSize: units.gu(2)
        enabled: true
    }

    ListSelector {
        id: applications
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        list: ["phone-app", "gallery-app", "camera-app"]
        onActivated: stageManager.activateApplication(desktopFileOf(entry))
        onDeactivated: applicationManager.stopProcess(applicationManager.getApplicationFromDesktopFile(desktopFileOf(entry)))
    }

    function desktopFileOf(entry) {
        return "/usr/share/applications/" + entry + ".desktop"
    }

    StageManagerTestCase {
        name: "StageManager - phone - 0 window case"
        when: windowShown
        stageManagerUnderTest: stageManager

        // left swipe does nothing when no applications open
        function test_leftEdgeSwipeDisabledWithNoApplicationsOpen() {
            rightEdgeSwipe()
            checkStageManagerOffScreen()
        }

        function test_stageManagerOffScreenByDefault() {
            checkStageManagerOffScreen()
        }
    }

    StageManagerTestCase {
        name: "StageManager - phone - 1 window case"
        when: windowShown
        stageManagerUnderTest: stageManager

        function init() {
            applications.activate("phone-app")
            waitForAnimationsToFinish()
        }

        // When application started and StageManager hidden, StageManager shows immediately
        function test_onLaunchStageManagerShown() {
            checkStageManagerOnScreen()
        }

        // Left-edge swipe the StageManager away animates the StageManager away
        function test_leftSwipeHidesStageManager() {
            leftEdgeSwipe()
            checkStageManagerOffScreen()
        }

        // Left-edge swipe the StageManager away unfocuses the application
        function test_leftSwipeUnfocusesApplication() {
            leftEdgeSwipe()
            checkStageManagerOffScreen()

            skip("FIXME: mainStageFocusedApplication not updated when application unfocused, see lp:1186980")
            tryCompare(applicationManager, "mainStageFocusedApplication", null)
        }

        // Left-edge swipe StageManager away. Right-edge swipe should restore it
        function test_rightSwipeRestoresApplication() {
            leftEdgeSwipe()
            checkStageManagerOffScreen()

            rightEdgeSwipe()
            checkStageManagerOnScreen()

            waitForAnimationsToFinish()

            tryCompare(applicationManager.mainStageFocusedApplication, "desktopFile",
                       desktopFileOf("phone-app"))
        }

        // Activate application. Left-edge swipe stages away. Use launcher to activate application
        // again - the StageManager should slide in and focus application
        function test_activateApplicationWhenStageHiddenRevealsApplication() {
            leftEdgeSwipe()
            checkStageManagerOffScreen()

            applications.activate("phone-app")
            checkStageManagerOnScreen()

            waitForAnimationsToFinish()

            tryCompare(applicationManager.mainStageFocusedApplication, "desktopFile",
                       desktopFileOf("phone-app"))
        }

        // Kill focused application. StageManager should hide
        function test_killingApplicationShouldHideStageManager() {
            applications.deactivate("phone-app")

            checkStageManagerOffScreen()
        }

        // Starting a second app while StageManager on-screen does nothing to StageManager
        function test_openingSecondAppWhileStageManagerOnScreen(){
            applications.activate("gallery-app")

            checkStageManagerOnScreen()

            waitForAnimationsToFinish()

            tryCompare(applicationManager.mainStageFocusedApplication, "desktopFile",
                       desktopFileOf("gallery-app"))
        }

        // Starting a second app while StageManager off-screen shows StageManager
        function test_openingSecondAppWhileStageManagerOffScreen(){
            leftEdgeSwipe()

            applications.activate("gallery-app")
            checkStageManagerOnScreen()

            waitForAnimationsToFinish()

            tryCompare(applicationManager.mainStageFocusedApplication, "desktopFile",
                       desktopFileOf("gallery-app"))
        }

        // Application focus change after animations complete
        function test_onLaunchApplicationGetsFocusedOnlyAfterAnimation() {
            applications.activate("gallery-app")

            verify(applicationManager.mainStageFocusedApplication.desktopFile !== desktopFileOf("gallery-app"))

            waitForAnimationsToFinish()

            compare(applicationManager.mainStageFocusedApplication.desktopFile, desktopFileOf("gallery-app"),
                    "Focus not on newly activated application after animation")
        }
    }

    StageManagerTestCase {
        name: "StageManager - phone - 2 window case"
        when: windowShown
        stageManagerUnderTest: stageManager

        function init() {
            applications.activate("phone-app")
            applications.activate("camera-app")
            waitForAnimationsToFinish()
        }

        function test_focusOrder() {
            compare(applicationManager.mainStageFocusedApplication.desktopFile, desktopFileOf("camera-app"),
                    "Focus not on last launched application")
        }

        // Check hiding and then revealing StageManager doesn't change the focus order
        function test_focusOrderAfterUnfocus() {
            leftEdgeSwipe()

            rightEdgeSwipe()
            waitForAnimationsToFinish()

            compare(applicationManager.mainStageFocusedApplication.desktopFile, desktopFileOf("camera-app"),
                    "Focus order changed somehow by hide/reveal of StageManager")
        }

        // Check that a hidden StageManager reacts correctly when background application activated
        function test_focusOrderWhenActivating() {
            leftEdgeSwipe()

            applications.activate("phone-app")

            waitForAnimationsToFinish()
            checkStageManagerOnScreen()

            tryCompare(applicationManager.mainStageFocusedApplication, "desktopFile", desktopFileOf("phone-app"))

            compare(applicationManager.mainStageFocusedApplication.desktopFile, desktopFileOf("phone-app"),
                    "Focus not on newly activated application when StageManager hidden")
        }

        // If the focused application dies, the StageManager should hide
        function test_foregroundApplicationDeathDismissesStageManager() {
            tryCompare(applicationManager.mainStageFocusedApplication, "desktopFile", desktopFileOf("camera-app"))

            skip("FIXME: StageManager does not hide when foreground application dies")
            applications.deactivate("camera-app")

            checkStageManagerOffScreen()
        }

        // If a background application dies, the StageManager should not react
        function test_nonForegroundApplicationDeathDoesNothing() {
            tryCompare(applicationManager.mainStageFocusedApplication, "desktopFile", desktopFileOf("camera-app"))
            applications.deactivate("phone-app")

            checkStageManagerOnScreen()
        }

        function test_fullScreenMode() {
            tryCompare(applicationManager.mainStageFocusedApplication, "desktopFile", desktopFileOf("camera-app"))

            tryCompare(stageManager, "fullscreenMode", true)

            rightEdgeSwipe()

            tryCompare(stageManager, "fullscreenMode", false)
        }
    }
}
