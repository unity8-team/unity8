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
import QtTest 1.0
import Unity.Test 0.1 as UT
import "../../../../Stages"

UT.UnityTestCase {
    property StageManager stageManagerUnderTest
    property point __lastMouseEvent: Qt.point(-1, -1)
    property SideStage sideStage: null
    property Stage mainStage: null

    onStageManagerUnderTestChanged: {
        mainStage = findChild(stageManagerUnderTest, "mainStage")
        sideStage = findChild(stageManagerUnderTest, "sideStage")
    }

    function cleanup() {
        resetMouseState()
        applications.deactivateAll()
        compare(applicationManager.mainStageApplications.count, 0, "Some main-stage application failed to quit")
        compare(applicationManager.sideStageApplications.count, 0, "Some side-stage application failed to quit")
        checkStageManagerOffScreen()
    }

    function rightEdgePress() {
        __lastMouseEvent.x = stageManagerUnderTest.width - (stageManagerUnderTest.edgeHandleSize / 2)
        __lastMouseEvent.y = stageManagerUnderTest.height / 2
        touchPress(stageManagerUnderTest, __lastMouseEvent.x, __lastMouseEvent.y)
    }

    function rightEdgeRelease() {
        touchRelease(stageManagerUnderTest, __lastMouseEvent.x, __lastMouseEvent.y)
        __lastMouseEvent = Qt.point(-1, -1)
    }

    function resetMouseState() {
        if (__lastMouseEvent !== Qt.point(-1, -1)) {
            rightEdgeRelease()
        }
    }

    function waitForAnimationsToFinish() {
        tryCompare(stageManagerUnderTest, "stageScreenshotsReady", false)
    }

    function leftEdgeSwipe(distance) {
        if (distance == undefined) distance = stageManagerUnderTest.width  / 3 * 2

        var x = stageManagerUnderTest.edgeHandleSize / 2
        var y = stageManagerUnderTest.height / 2
        touchFlick(stageManagerUnderTest, x, y,
                   x + distance, y)
    }

    function rightEdgeSwipe(distance) {
        if (distance == undefined) distance = stageManagerUnderTest.width  / 3 * 2

        var x = stageManagerUnderTest.width - (stageManagerUnderTest.edgeHandleSize / 2)
        var y = stageManagerUnderTest.height / 2
        touchFlick(stageManagerUnderTest, x, y,
                   x - distance, y)
    }

    function sideStageHandleRightSwipe(distance) {
        if (distance == undefined) distance = sideStage.width / 3 * 2

        var x = sideStage.x - (sideStage.rightEdgeDraggingAreaWidth / 2)
        var y = sideStage.height / 2
        touchFlick(stageManagerUnderTest, x, y,
                   x + distance, y)
    }

    function checkStageManagerOffScreen() {
        tryCompare(stageManagerUnderTest, "animatedProgress", 0) //0 means off-screen
        tryCompare(stageManagerUnderTest, "shown", false)
    }

    function checkStageManagerOnScreen() {
        tryCompare(stageManagerUnderTest, "animatedProgress", 1) //1 means on-screen
        tryCompare(stageManagerUnderTest, "shown", true)
    }
}
