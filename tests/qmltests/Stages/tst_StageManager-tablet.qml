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
    width: units.gu(100)
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

        list: ["phone-app", "facebook-webapp", "gallery-app"]
        onActivated: stageManager.activateApplication(desktopFileOf(entry))
        onDeactivated: applicationManager.stopProcess(applicationManager.getApplicationFromDesktopFile(desktopFileOf(entry)))
    }

    function desktopFileOf(entry) {
        return "/usr/share/applications/" + entry + ".desktop"
    }

    StageManagerTestCase {
        name: "StageManager - tablet - 1 main-stage window case"
        when: windowShown
        stageManagerUnderTest: stageManager

        function init() {
            applications.activate("gallery-app") //main-stage app
            waitForAnimationsToFinish()
        }

        // Right-edge press does not change main-stage app
        function test_rightEdgeSwipeDoesNotChangeMainStageApp() {
            rightEdgePress()
            waitForRendering(stageManager)
            compare(mainStage.oldApplicationScreenshot.visible, false) // i.e. no screenshot animation occurs
        }
    }

    StageManagerTestCase {
        name: "StageManager - tablet - 1 side-stage window case"
        when: windowShown
        stageManagerUnderTest: stageManager

        function init() {
            applications.activate("phone-app") // side-stage app
            waitForAnimationsToFinish()
        }

        // Check loaded as side-stage application
        function test_sideStage() {
            tryCompare(applicationManager.sideStageFocusedApplication, "desktopFile", desktopFileOf("phone-app"))
            compare(applicationManager.mainStageFocusedApplication, null)
        }

        // When application started and StageManager hidden, StageManager shows immediately
        function test_onLaunchStageManagerShown() {
            checkStageManagerOnScreen()
        }

        // Check side-stage positioned correctly
        function test_sideStagePositionedCorrectly() {
            compare(sideStage.x, stageManager.width - units.gu(40), "Sidestage not positioned correctly")
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

            skip("FIXME: sideStageFocusedApplication not updated when application unfocused, see lp:1186980")
            tryCompare(applicationManager, "sideStageFocusedApplication", null)
        }

        // Left-edge swipe StageManager away. Right-edge swipe should restore it
        function test_rightSwipeRestoresApplication() {
            leftEdgeSwipe()
            checkStageManagerOffScreen()

            rightEdgeSwipe()
            checkStageManagerOnScreen()

            waitForAnimationsToFinish()

            tryCompare(applicationManager.sideStageFocusedApplication, "desktopFile", desktopFileOf("phone-app"))
        }

        // Activate application. Left-edge swipe stages away. Use launcher to activate application
        // again - the StageManager should slide in and focus application
        function test_activateApplicationWhenStageHiddenRevealsApplication() {
            leftEdgeSwipe()
            checkStageManagerOffScreen()

            applications.activate("phone-app")
            checkStageManagerOnScreen()

            waitForAnimationsToFinish()

            tryCompare(applicationManager.sideStageFocusedApplication, "desktopFile", desktopFileOf("phone-app"))
        }

        // Kill focused application. StageManager should hide
        function test_killingApplicationShouldHideStageManager() {
            applications.deactivate("phone-app")

            checkStageManagerOffScreen()
        }

        // Starting a second side-stage app while StageManager on-screen does nothing to StageManager
        function test_openingSecondSideStageAppWhileStageManagerOnScreen(){
            applications.activate("facebook-webapp") //side-stage app
            checkStageManagerOnScreen()

            waitForAnimationsToFinish()
            tryCompare(applicationManager.sideStageFocusedApplication, "desktopFile", desktopFileOf("facebook-webapp"))
        }

        // Starting a second side-stage app while StageManager off-screen shows StageManager
        function test_openingSecondSideStageAppWhileStageManagerOffScreen(){
            leftEdgeSwipe()

            applications.activate("facebook-webapp") //side-stage app
            checkStageManagerOnScreen()

            waitForAnimationsToFinish()
            tryCompare(applicationManager.sideStageFocusedApplication, "desktopFile", desktopFileOf("facebook-webapp"))
        }


        // Starting a main-stage app while StageManager off-screen shows StageManager
        function test_openingMainStageAppWhileStageManagerOffScreen(){
            leftEdgeSwipe()
            checkStageManagerOffScreen()

            applications.activate("gallery-app") //main-stage app
            checkStageManagerOnScreen()

            waitForAnimationsToFinish()
            tryCompare(applicationManager.mainStageFocusedApplication, "desktopFile", desktopFileOf("gallery-app"))
        }

        // Application focus change after animations complete
        function test_onLaunchApplicationGetsFocusedOnlyAfterAnimation() {
            applications.activate("facebook-webapp") //side-stage app

            verify(applicationManager.sideStageFocusedApplication.desktopFile !== desktopFileOf("facebook-webapp"))

            waitForAnimationsToFinish()
            compare(applicationManager.sideStageFocusedApplication.desktopFile, desktopFileOf("facebook-webapp"),
                    "Newly activated application does not have focus after animation")
        }

        // Right-edge press changes side-stage app
        function test_rightEdgeSwipeChangesSideStageOnly() {
            rightEdgePress()
            tryCompareFunction( function() {
                return sideStage.oldApplicationScreenshot.scale < 1
            }, true)
        }

        // Right-swipe of side-stage handle does nothing
        function test_rightSwipeOfSideStageHandleDoesNothing() {
            sideStageHandleRightSwipe()

            compare(sideStage.x, stageManager.width - units.gu(40),
                    "Side-stage was incorrectly dismissed when no main-stage application open")
        }
    }

    StageManagerTestCase {
        name: "StageManager - tablet - 1 side-stage & 1 main-stage window case"
        when: windowShown
        stageManagerUnderTest: stageManager

        function init() {
            applications.activate("gallery-app") //main-stage app
            applications.activate("phone-app")   //side-stage app
            waitForAnimationsToFinish()
        }

        function test_focusOrder() {
            compare(applicationManager.mainStageFocusedApplication.desktopFile, desktopFileOf("gallery-app"),
                    "Main-stage application not got focus after activation")
            compare(applicationManager.sideStageFocusedApplication.desktopFile, desktopFileOf("phone-app"),
                    "Side-stage application not got focus after activation")
        }

        // Check hiding and then revealing StageManager doesn't change the focus order
        function test_focusOrderAfterUnfocus() {
            leftEdgeSwipe()

            rightEdgeSwipe()
            waitForAnimationsToFinish()

            compare(applicationManager.mainStageFocusedApplication.desktopFile, desktopFileOf("gallery-app"),
                    "Main-stage application lost focus from StageManager hide/show")
            compare(applicationManager.sideStageFocusedApplication.desktopFile, desktopFileOf("phone-app"),
                    "Side-stage application lost focus from StageManager hide/show")
        }

        // Check that a hidden StageManager reacts correctly when already-open side-stage application activated
        function test_focusOrderWhenActivatingSideStage() {
            leftEdgeSwipe()

            applications.activate("phone-app")   //side-stage app

            checkStageManagerOnScreen()
        }

        // Check that a hidden StageManager reacts correctly when already-open main-stage application activated
        function test_focusOrderWhenActivatingMainStage() {
            leftEdgeSwipe()

            applications.activate("gallery-app") //main-stage app

            checkStageManagerOnScreen()
        }

        // If the main-stage application dies, the StageManager should stay on screen
        function test_foregroundMainStageApplicationDeathDoesNothing() {
            applications.deactivate("gallery-app") //main-stage app

            checkStageManagerOnScreen()
            compare(applicationManager.sideStageFocusedApplication.desktopFile, desktopFileOf("phone-app"),
                    "Side-stage application lost focus after main-stage application died")
        }

        // If the side-stage application dies, the StageManager should stay on screen
        function test_foregroundSideStageApplicationDeathDoesNothing() {
            applications.deactivate("phone-app") //side-stage app

            checkStageManagerOnScreen()
            compare(applicationManager.mainStageFocusedApplication.desktopFile, desktopFileOf("gallery-app"),
                    "Main-stage application lost focus after side-stage application died")
        }

        // If the side-stage application dies, the side stage should hide
        function test_foregroundSideStageApplicationDeathHidesSideStage() {
            applications.deactivate("phone-app") //side-stage app

            tryCompareFunction( function() {
                return sideStage.x > stageManager.width
            }, true)
        }

        // Right-edge swipe changes side-stage app
        function test_rightEdgeSwipeChangesSideStage() {
            tryCompare(sideStage, "x", stageManager.width - sideStage.width) //ensure side-stage open

            waitForAnimationsToFinish()
            rightEdgePress()
            waitForRendering(stageManager)
            tryCompareFunction( function() {
                return sideStage.oldApplicationScreenshot.scale < 1
            }, true)
        }

        // Right-edge swipe does not change main-stage app
        function test_rightEdgeSwipeDoesNotChangeMainStage() {
            rightEdgePress()
            waitForRendering(stageManager)
            compare(mainStage.oldApplicationScreenshot.scale, 1,
                    "Right-edge swipe animating main-stage while side-stage app open")
        }

        // Right-swipe of side-stage handle dismisses side-stage
        function test_rightSwipeOfSideStageHandleHidesSideStage() {
            sideStageHandleRightSwipe()
            waitForAnimationsToFinish()

            tryCompare(sideStage, "x", stageManager.width + sideStage.handleSizeCollapsed)
        }

        // Right-swipe of side-stage unfocuses side-stage app
        function test_rightSwipeOfSideStageHandleUnfocusesSideStageApp() {
            tryCompare(sideStage, "x", stageManager.width - sideStage.width) //ensure side-stage open

            sideStageHandleRightSwipe()
            waitForAnimationsToFinish()

            compare(applicationManager.mainStageFocusedApplication.desktopFile, desktopFileOf("gallery-app"),
                    "Right-edge swipe of side-stage app changed main-stage focus")
            skip("FIXME: sideStageFocusedApplication not updated when application unfocused, see lp:1186980")
            //tryCompare(applicationManager, "sideStageFocusedApplication", null)
        }

        // Hidden side-stage can be right-edge swiped back
        function test_rightEdgeSwipeRestoresHiddenSideStageApp() {
            sideStageHandleRightSwipe()
            waitForAnimationsToFinish()

            rightEdgeSwipe()
            waitForAnimationsToFinish()

            tryCompare(sideStage, "x", stageManager.width - units.gu(40))
        }

        // Hidden side-stage app when right-edge swiped has focus restored
        function test_rightEdgeSwipeRestoresFocusToSideStageApp() {
            sideStageHandleRightSwipe()
            waitForAnimationsToFinish()

            rightEdgeSwipe()
            waitForAnimationsToFinish()

            compare(applicationManager.sideStageFocusedApplication.desktopFile, desktopFileOf("phone-app"),
                    "Side-stage app not returned focus after StageManager un-hidden")
            compare(applicationManager.mainStageFocusedApplication.desktopFile, desktopFileOf("gallery-app"),
                    "Main-stage app not returned focus after StageManager un-hidden")
        }

        // Hide side-stage, then activate the side-stage application. It should slide back in
        function test_activatingHiddenSideStageAppSlidesItIn() {
            sideStageHandleRightSwipe()
            waitForAnimationsToFinish()

            applications.activate("phone-app") //side-stage app
            waitForAnimationsToFinish()

            tryCompare(sideStage, "x", stageManager.width - sideStage.width)
        }

        // Hide side-stage, then left-swipe to hide whole StageManager. Activate side-stage app
        // StageManager should slide in, with side-stage app fixed in place (i.e. not sliding independently)
        function test_activatingHiddenSideStageAppWhenStageManagerHidden() {
            sideStageHandleRightSwipe()
            waitForAnimationsToFinish()

            leftEdgeSwipe(units.gu(160))
            checkStageManagerOffScreen()

            applications.activate("phone-app") //side-stage app
            tryCompare(sideStage, "x", stageManager.width - units.gu(40))
        }

        // Starting a main-stage app while StageManager on-screen does nothing to StageManager
        function test_openingSecondMainStageAppWhileStageManagerOnScreen(){
            applications.activate("gallery-app") //main-stage app
            checkStageManagerOnScreen()

            waitForAnimationsToFinish()
            tryCompare(applicationManager.mainStageFocusedApplication, "desktopFile", desktopFileOf("gallery-app"))
        }
    }
}
