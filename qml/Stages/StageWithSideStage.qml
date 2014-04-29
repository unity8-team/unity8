/*
 * Copyright (C) 2014 Canonical, Ltd.
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
import Ubuntu.Components 0.1
import "../Components"
import Unity.Application 0.1
import Ubuntu.Gestures 0.1
import Utils 0.1

Item {
    id: root
    objectName: "stages"
    anchors.fill: parent

    // Controls to be set from outside
    property bool shown: false
    property bool moving: false
    property int dragAreaWidth

    // State information propagated to the outside
    readonly property bool painting: mainStageImage.visible || sideStageImage.visible || sideStageSnapAnimation.running
    property bool fullscreen: priv.focusedApplication ? priv.focusedApplication.fullscreen : false
    property bool overlayMode: (sideStageImage.shown && priv.mainStageAppId.length == 0) || priv.overlayOverride
                               || (priv.mainStageAppId.length == 0 && sideStageSnapAnimation.running)

    readonly property int overlayWidth: priv.overlayOverride ? 0 : priv.sideStageWidth

    onShownChanged: {
        if (!shown) {
            priv.mainStageAppId = "";
        }
    }

    onMovingChanged: {
        if (moving) {
            if (!priv.mainStageAppId && !priv.sideStageAppId) {
                // Pulling in from the right, make the last used (topmost) app visible
                var application = ApplicationManager.get(0);
                if (application.stage == ApplicationInfoInterface.SideStage) {
                    sideStageImage.application = application;
                    sideStageImage.x = root.width - sideStageImage.width
                    sideStageImage.visible = true;
                } else {
                    mainStageImage.application = application;
                    mainStageImage.visible = true;
                }
            } else {
                priv.requestNewScreenshot(ApplicationInfoInterface.MainStage)
                if (priv.focusedApplicationId == priv.sideStageAppId) {
                    priv.requestNewScreenshot(ApplicationInfoInterface.SideStage)
                }
            }
        } else {
            mainStageImage.visible = false;
            sideStageImage.visible = false;
        }
    }

    QtObject {
        id: priv

        property int sideStageWidth: units.gu(40)


        property string sideStageAppId
        property string mainStageAppId

        property string appId0
        property string appId1


        property var sideStageApp: ApplicationManager.findApplication(sideStageAppId)
        property var mainStageApp: ApplicationManager.findApplication(mainStageAppId)

        property string sideStageScreenshot: sideStageApp ? sideStageApp.screenshot : ""
        property string mainStageScreenshot: mainStageApp ? mainStageApp.screenshot : ""

        property string focusedApplicationId: ApplicationManager.focusedApplicationId
        property var focusedApplication: ApplicationManager.findApplication(focusedApplicationId)
        property url focusedScreenshot: focusedApplication ? focusedApplication.screenshot : ""

        property bool waitingForMainScreenshot: false
        property bool waitingForSideScreenshot: false
        property bool waitingForScreenshots: waitingForMainScreenshot || waitingForSideScreenshot

        property string startingAppId: ""

        // Keep overlayMode even if there is no focused app (to allow pulling in the sidestage from the right)
        property bool overlayOverride: false

        onFocusedApplicationChanged: {
            if (focusedApplication) {
                if (focusedApplication.stage == ApplicationInfoInterface.MainStage) {
                    mainStageAppId = focusedApplicationId;
                    priv.overlayOverride = false;
                    if (priv.startingAppId == focusedApplicationId && sideStageImage.shown) {
                        // There was already a sidestage app on top. bring it back!
                        ApplicationManager.focusApplication(priv.sideStageAppId)
                        priv.startingAppId = "";
                    }
                } else if (focusedApplication.stage == ApplicationInfoInterface.SideStage) {
                    sideStageAppId = focusedApplicationId;
                    if (priv.startingAppId == focusedApplicationId && !sideStageImage.shown) {
                        sideStageImage.snapToApp(focusedApplication);
                        priv.startingAppId = "";
                    }
                }
            } else if (root.overlayMode){
                sideStageImage.snapTo(root.width)
            }

            appId0 = ApplicationManager.get(0).appId;
            appId1 = ApplicationManager.get(1).appId;
        }

        onMainStageScreenshotChanged: {
            waitingForMainScreenshot = false;
        }

        onSideStageScreenshotChanged: {
            waitingForSideScreenshot = false;
        }

        onFocusedScreenshotChanged: {
            waitingForSideScreenshot = false;
        }

        onWaitingForScreenshotsChanged: {
            if (waitingForScreenshots) {
                return;
            }

            if (root.moving) {
                if (mainStageAppId) {
                    mainStageImage.application = mainStageApp
                    mainStageImage.visible = true;
                }
                if (sideStageAppId && focusedApplicationId == sideStageAppId) {
                    sideStageImage.application = sideStageApp;
                    sideStageImage.x = root.width - sideStageImage.width
                    sideStageImage.visible = true;
                }
            }
            if (sideStageHandleMouseArea.pressed) {
                if (sideStageAppId) {
                    sideStageImage.application = sideStageApp;
                    sideStageImage.x = root.width - sideStageImage.width
                    sideStageImage.visible = true;
                }
                if (mainStageAppId) {
                    mainStageImage.application = mainStageApp
                    mainStageImage.visible = true;
                }
            }
        }

        function requestNewScreenshot(stage) {
            if (stage == ApplicationInfoInterface.MainStage && mainStageAppId) {
                waitingForMainScreenshot = true;
                ApplicationManager.updateScreenshot(mainStageAppId);
            } else if (stage == ApplicationInfoInterface.SideStage && sideStageAppId) {
                waitingForSideScreenshot = true;
                ApplicationManager.updateScreenshot(sideStageAppId);
            }
        }

    }
    // FIXME: the signal connection seems to get lost with the fake application manager.
    Connections {
        target: priv.sideStageApp
        onScreenshotChanged: priv.sideStageScreenshot = priv.sideStageApp.screenshot
    }
    Connections {
        target: priv.mainStageApp
        onScreenshotChanged: priv.mainStageScreenshot = priv.mainStageApp.screenshot
    }

    Connections {
        target: ApplicationManager

        onApplicationAdded: {
            priv.startingAppId = appId;
            splashScreenTimer.start();
            var application = ApplicationManager.findApplication(appId)
            if (application.stage == ApplicationInfoInterface.SideStage) {
                sideStageSplash.visible = true;
            } else if (application.stage == ApplicationInfoInterface.MainStage) {
                mainStageSplash.visible = true;
            }
        }

        onFocusRequested: {
            var application = ApplicationManager.findApplication(appId)
            if (application.stage == ApplicationInfoInterface.SideStage) {
                if (!root.shown) {
                    priv.mainStageAppId = "";
                    mainStageImage.application = null
                }
                if (sideStageImage.shown) {
                    sideStageImage.switchTo(application);
                    if (priv.mainStageAppId) {
                        mainStageImage.application = priv.mainStageApp;
                        mainStageImage.visible = true;
                    }
                } else {
                    sideStageImage.application = application;
                    sideStageImage.snapToApp(application);
                }
            } else if (application.stage == ApplicationInfoInterface.MainStage) {
                if (root.shown) {
                    if (sideStageImage.shown) {
                        sideStageImage.application = priv.sideStageApp;
                        sideStageImage.visible = true;
                    }
                    priv.mainStageAppId = application.appId;
                    mainStageImage.switchTo(application)
                    ApplicationManager.focusApplication(appId)
                    if (sideStageImage.shown) {
                        // There was already a focused SS app. Bring it back
                        ApplicationManager.focusApplication(priv.sideStageAppId)
                    }
                } else {
                    if (sideStageImage.shown) {
                        sideStageImage.visible = false;
                        sideStageImage.x = root.width;
                    }

                    mainStageImage.application = application;
                    ApplicationManager.focusApplication(appId)
                }
            }
        }

        onApplicationRemoved: {
            if (priv.mainStageAppId == appId) {
                priv.mainStageAppId = "";
            }
            if (priv.sideStageAppId == appId) {
                priv.sideStageAppId = "";
            }
            if (priv.sideStageAppId.length == 0) {
                sideStageImage.shown = false;
                priv.overlayOverride = false;
            }
        }

    }

    Timer {
        id: splashScreenTimer
        // FIXME: apart from removing this completely in the future and make the app surface paint
        // meaningful stuff, also check for colin's stuff to land so we can shape 1.4 secs away from here
        // https://code.launchpad.net/~cjwatson/upstart-app-launch/libclick-manifest/+merge/210520
        // https://code.launchpad.net/~cjwatson/upstart-app-launch/libclick-pkgdir/+merge/209909
        interval: 1700
        repeat: false
        onTriggered: {
            mainStageSplash.visible = false;
            sideStageSplash.visible = false;
        }
    }

    SwitchingApplicationImage {
        id: mainStageImage
        anchors.bottom: parent.bottom
        width: parent.width
        visible: false

        onSwitched: {
            sideStageImage.visible = false;
        }
    }

    Rectangle {
        id: mainStageSplash
        anchors.fill: root
        anchors.rightMargin: root.width - sideStageImage.x
        color: "white"
    }

    SidestageHandle {
        id: sideStageHandle
        anchors { top: parent.top; right: sideStageImage.left; bottom: parent.bottom }
        width: root.dragAreaWidth
        visible: root.shown && priv.sideStageAppId && sideStageImage.x < root.width

    }
    MouseArea {
        id: sideStageHandleMouseArea
        anchors { top: parent.top; right: parent.right; bottom: parent.bottom; rightMargin: sideStageImage.shown ? sideStageImage.width : 0}
        width: root.dragAreaWidth
        visible: priv.sideStageAppId

        property var dragPoints: new Array()

        onPressed: {
            priv.requestNewScreenshot(ApplicationInfoInterface.SideStage)
            if (priv.mainStageAppId) {
                priv.requestNewScreenshot(ApplicationInfoInterface.MainStage)
            }
        }

        onMouseXChanged: {
            dragPoints.push(mouseX)

            var dragPoint = root.width + mouseX;
            if (sideStageImage.shown) {
                dragPoint -= sideStageImage.width
            }
            sideStageImage.x = Math.max(root.width - sideStageImage.width, dragPoint)
        }

        onReleased: {
            var distance = 0;
            var lastX = dragPoints[0];
            var oneWayFlick = true;
            for (var i = 0; i < dragPoints.length; ++i) {
                if (dragPoints[i] < lastX) {
                    oneWayFlick = false;
                }
                distance += dragPoints[i] - lastX;
                lastX = dragPoints[i];
            }
            dragPoints = [];

            if (oneWayFlick || distance > sideStageImage.width / 2) {
                sideStageImage.snapTo(root.width)
            } else {
                sideStageImage.snapToApp(priv.sideStageApp)
            }
        }
    }

    SwitchingApplicationImage {
        id: sideStageImage
        width: priv.sideStageWidth
        height: root.height
        x: root.width
        anchors.bottom: parent.bottom
        visible: true
        property bool shown: false

        onSwitched: {
            mainStageImage.visible = false;
            ApplicationManager.focusApplication(application.appId)
        }

        function snapTo(targetX) {
            sideStageSnapAnimation.targetX = targetX
            sideStageImage.visible = true;
            if (priv.mainStageAppId) {
                mainStageImage.application = priv.mainStageApp
                mainStageImage.visible = true;
            }
            sideStageSnapAnimation.start();
        }

        function snapToApp(application) {
            sideStageImage.application = application
            sideStageSnapAnimation.snapToId = application.appId;
            snapTo(root.width - sideStageImage.width);
        }

        SequentialAnimation {
            id: sideStageSnapAnimation
            property int targetX: root.width
            property string snapToId

            UbuntuNumberAnimation { target: sideStageImage; property: "x"; to: sideStageSnapAnimation.targetX; duration: UbuntuAnimation.SlowDuration }
            ScriptAction {
                script: {
                    if (sideStageSnapAnimation.targetX == root.width) {
                        if (priv.mainStageAppId) {
                            ApplicationManager.focusApplication(priv.mainStageAppId)
                        } else {
                            priv.overlayOverride = true;
                            ApplicationManager.unfocusCurrentApplication();
                        }
                        sideStageImage.shown = false;
                    }
                    if (sideStageSnapAnimation.snapToId) {
                        ApplicationManager.focusApplication(sideStageSnapAnimation.snapToId)
                        sideStageSnapAnimation.snapToId = "";
                        sideStageImage.shown = true;
                        priv.overlayOverride = false;
                    }
                    sideStageImage.visible = false;
                    mainStageImage.visible = false;
                }
            }
        }
    }

    Rectangle {
        id: sideStageSplash
        anchors.fill: parent
        anchors.leftMargin: sideStageImage.x
        color: "white"
    }

    Flickable {
        id: spreadView
        anchors.fill: parent

        contentWidth: spreadRow.width - shift
        contentX: -shift

        // The flickable needs to fill the screen in order to get touch events all over.
        // However, we don't want to the user to be able to scroll back all the way. For
        // that, the beginning of the gesture starts with a negative value for contentX
        // so the flickable wants to pull it into the view already. "shift" tunes the
        // distance where to "lock" the content.
        property real shift: width / 2
        property real shiftedContentX: contentX + shift

        property int tileDistance: width / 4

        // 0: first app coming in
        // 1: apps mving from right edge to spread
        // 2: spread
        property int phase: 0

        // Those markers mark the various positions in the spread (ratio to screen width from right to left):
        // 0 - 1: following finger, snap back to the beginning on release
        property real positionMarker1: 0.3
        // 1 - 2: curved snapping movement, snap to app 1 on release
        property real positionMarker2: 0.45
        // 2 - 3: movement follows finger, snaps back to app 1 on release
        property real positionMarker3: 0.6
        // passing 3, we detach movement from the finger and snap to 4
        property real positionMarker4: 0.9

        // This is where the first app snaps to when bringing it in from the right edge.
        property real snapPosition: 0.75

        Rectangle { anchors.fill: parent; border.width: units.gu(1); border.color: "black"; color: "magenta"; opacity: .5}

        state: {
            if (priv.mainStageAppId && !priv.sideStageAppId) {
                return "main";
            }
            if (!priv.mainStageAppId && priv.sideStageAppId) {
                return "overlay";
            }
            if (priv.mainStageAppId && priv.sideStageAppId) {
                return "mainAndOverlay";
            }
            return "invalid";
        }

        states: [
            State {
                name: "invalid" // temporary until Dash is an app and we always have a main stage app
            },
            State {
                name: "main"
            },
            State {
                name: "overlay"
            },
            State {
                name: "mainAndOverlay"
            },
            State {
                name: "mainAndSplit"
            }
        ]

        onStateChanged: print("#+#+#+#+#+#+#+# SpreadView state changed to:", state)

        property int nextInStack: {
            switch (state) {
            case "main":
                if (ApplicationManager.count > 1) {
                    return 1;
                }
                return -1;
            case "mainAndOverlay":
                if (ApplicationManager.count <= 2) {
                    return -1;
                }
                print("nextinstack calculation! appId0", priv.appId0, "appid1", priv.appId1, "MS", priv.mainStageAppId, "SS", priv.sideStageAppId)
                if (priv.appId0 == priv.mainStageAppId || priv.appId0 == priv.sideStageAppId) {
                    if (priv.appId1 == priv.mainStageAppId || priv.appId1 == priv.sideStageAppId) {
                        return 2;
                    }
                    return 1;
                }
                return 0;
            }
            print("unhandled nextInStack case!!!!!");
            return -1;
        }

        // This is the upcoming state, when doing a short right edge gesture.
        property string nextState: {
            switch (state) {
            case "main":
                if (ApplicationManager.count > 1) {
                    if (ApplicationManager.get(1).stage == ApplicationInfoInterface.SideStage) {
                        return "mainAndOverlay";
                    }
                    if (ApplicationManager.get(1).stage == ApplicationInfoInterface.MainStage) {
                        return "main";
                    }
                } else {
                    return "main";
                }

                break;
            case "mainAndOverlay":
                if (ApplicationManager.count > 2) {
                    if (ApplicationManager.get(2).stage == ApplicationInfoInterface.SideStage) {
                        return "mainAndOverlay";
                    }
                    if (ApplicationManager.get(2).stage == ApplicationInfoInterface.MainStage) {
                        return "mainAndOverlay";
                    }
                } else {
                    return "mainAndOverlay";
                }
                break;
            case "mainAndSplit":
                if (ApplicationManager.count > 2) {
                    if (ApplicationManager.get(2).stage == ApplicationInfoInterface.SideStage) {
                        return "mainAndOverlay";
                    }
                    if (ApplicationManager.get(2).stage == ApplicationInfoInterface.MainStage) {
                        return "mainAndOverlay";
                    }
                } else {
                    return "mainAndOverlay";
                }
                break;
            }
            return "invalid";
        }

        Item {
            id: spreadRow
            // This width controls how much the spread can be flicked left/right. It's composed of:
            //  tileDistance * app count (with a minimum of 3 apps, in order to also allow moving 1 and 2 apps a bit)
            //  + some constant value (still scales with the screen width) which looks good and somewhat fills the screen
            width: Math.max(3, ApplicationManager.count) * spreadView.tileDistance + (spreadView.width - spreadView.tileDistance) * 1.5
            height: spreadView.height
            Rectangle {anchors.fill: parent; color: "khaki"; z: -2 }

            x: spreadView.contentX

            Repeater {
                id: spreadRepeater
                model: ApplicationManager

                delegate: SWSSTransformedSpreadDelegate {
                    id: spreadDelegate
                    z: {
                        print("calculating z for", model.appId);
                        if (active && model.stage == ApplicationInfoInterface.MainStage) {
                            print("z for", model.appId, "is", 0);
                            return 0;
                        }
                        if (active && model.stage == ApplicationInfoInterface.SideStage) {
                            print("z for", model.appId, "is", 2);
                            return 2;
                        }
                        if (index <= 2 && model.stage == ApplicationInfoInterface.MainStage) {
                            print("z for", model.appId, "is", 1);
                            return 1;
                        }
                        print("default z for", model.appId, "is", index + 3);
                        return index + 3;
                    }
                    x: spreadView.width
//                    x: index == 0 ? 0 : spreadView.width /2  + (index - 1) * spreadView.tileDistance // FIXME: remove /2
                    y: 0
                    active: model.appId == priv.mainStageAppId || model.appId == priv.sideStageAppId

//                    width: units.gu(10)
                    height: spreadView.height
                    width: ApplicationManager.get(index).stage == ApplicationInfoInterface.MainStage ? spreadView.width : sideStageImage.width
//                    height: spreadView.height

                    Rectangle {
                        anchors.fill: parent
                        color: "#0000FF55"
                        Label {
                            anchors.centerIn: parent
                            text: index + " " + model.appId + " z:" + spreadDelegate.z
                            color: "green"
                        }
                    }

                    // Each tile has a different progress value running from 0 to 1.
                    // A progress value of 0 means the tile is at the right edge. 1 means the tile has reched the left edge.
                    progress: {
                        switch (spreadView.phase) {
                        case 0:
                            return spreadView.shiftedContentX / spreadView.width;
                        case 1:
                            return 1;
                        }

                        var tileProgress = (spreadView.shiftedContentX - index * spreadView.tileDistance) / spreadView.width;
                        if (index == spreadView.nextInStack && spreadView.phase < 2) {
                            print("calculating progress for nextInStack", tileProgress)
                            tileProgress += index * spreadView.tileDistance / spreadView.width;
                            print("foo", tileProgress)
                        }

//                        // Tile 1 needs to move directly from the beginning...
//                        if (index == 1 && spreadView.phase < 2) {
//                            tileProgress += spreadView.tileDistance / spreadView.width;
//                        }
//                        // If we have already 2 visible, tile 2 needs to be shifted too
//                        if (index == 2 && !active && spreadView.state == "mainAndOverlay") {
//                            tileProgress += spreadView.tileDistance / spreadView.width;
//                        }

//                        if (index == 2) print("updating progress:", tileProgress)
                        return tileProgress;
                    }

                    // This mostly is the same as progress, just adds the snapping to phase 1 for tiles 0 and 1
                    animatedProgress: {
                        if (spreadView.phase == 0 && index < 2) {
                            if (progress < spreadView.positionMarker1) {
                                return progress;
                            } else if (progress < spreadView.positionMarker1 + snappingCurve.period){
                                return spreadView.positionMarker1 + snappingCurve.value * 3;
                            } else {
                                return spreadView.positionMarker2;
                            }
                        }
                        return progress;
                    }

                    EasingCurve {
                        id: snappingCurve
                        type: EasingCurve.OutQuad
                        period: 0.05
                        progress: spreadDelegate.progress - spreadView.positionMarker1
                    }

                }
            }
        }
    }

    EdgeDragArea {
        id: spreadDragArea
        direction: Direction.Leftwards
        enabled: ApplicationManager.count > 1 && spreadView.phase != 2

        anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
        width: root.dragAreaWidth

        Rectangle { anchors.fill: parent; color: "green" }

        // Sitting at the right edge of the screen, this EdgeDragArea directly controls the spreadView when
        // attachedToView is true. When the finger movement passes positionMarker3 we detach it from the
        // spreadView and make the spreadView snap to positionMarker4.
        property bool attachedToView: true

        property var gesturePoints: new Array()

        onTouchXChanged: {
//            print("touchXchanged", dragging, attachedToView)
            if (!dragging) {
                // Initial touch. Let's update the screenshot and reset the spreadView to the starting position.
//                priv.requestNewScreenshot();
                spreadView.phase = 0;
                spreadView.contentX = -spreadView.shift;
            }
            if (dragging && attachedToView) {
                // Gesture recognized. Let's move the spreadView with the finger
                spreadView.contentX = -touchX + spreadDragArea.width - spreadView.shift;
            }
            if (attachedToView && spreadView.shiftedContentX >= spreadView.width * spreadView.positionMarker3) {
                // We passed positionMarker3. Detach from spreadView and snap it.
//                attachedToView = false;
                spreadView.snap();
            }
            gesturePoints.push(touchX);
        }

        onStatusChanged: {
            if (status == DirectionalDragArea.Recognized) {
                attachedToView = true;
            }
        }

        onDraggingChanged: {
            if (dragging) {
                // Gesture recognized. Start recording this gesture
                gesturePoints = [];
                return;
            }

            // Ok. The user released. Find out if it was a one-way movement.
            var oneWayFlick = true;
            var smallestX = spreadDragArea.width;
            for (var i = 0; i < gesturePoints.length; i++) {
                if (gesturePoints[i] >= smallestX) {
                    oneWayFlick = false;
                    break;
                }
                smallestX = gesturePoints[i];
            }
            gesturePoints = [];

            if (oneWayFlick && spreadView.shiftedContentX > units.gu(2) &&
                    spreadView.shiftedContentX < spreadView.positionMarker1 * spreadView.width) {
                // If it was a short one-way movement, do the Alt+Tab switch
                // no matter if we didn't cross positionMarker1 yet.
                spreadView.snapTo(1);
            } else if (!dragging && attachedToView) {
                // otherwise snap to the closest snap position we can find
                // (might be back to start, to app 1 or to spread)
                spreadView.snap();
            }
        }
    }
}
