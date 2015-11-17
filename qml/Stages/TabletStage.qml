/*
 * Copyright (C) 2014-2015 Canonical, Ltd.
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
import Ubuntu.Gestures 0.1
import Unity.Application 0.1
import Utils 0.1
import Powerd 0.1
import "../Components"

AbstractStage {
    id: root
    objectName: "stages"
    anchors.fill: parent

    // Functions to be called from outside
    function updateFocusedAppOrientation() {
        var mainStageAppIndex = priv.indexOf(priv.mainStageAppId);
        if (mainStageAppIndex >= 0 && mainStageAppIndex < spreadRepeater.count) {
            spreadRepeater.itemAt(mainStageAppIndex).matchShellOrientation();
        }

        for (var i = 0; i < spreadRepeater.count; ++i) {

            if (i === mainStageAppIndex) {
                continue;
            }

            var spreadDelegate = spreadRepeater.itemAt(i);

            var delta = spreadDelegate.appWindowOrientationAngle - root.shellOrientationAngle;
            if (delta < 0) { delta += 360; }
            delta = delta % 360;

            var supportedOrientations = spreadDelegate.application.supportedOrientations;
            if (supportedOrientations === Qt.PrimaryOrientation) {
                supportedOrientations = spreadDelegate.orientations.primary;
            }

            if (delta === 180 && (supportedOrientations & spreadDelegate.shellOrientation)) {
                spreadDelegate.matchShellOrientation();
            }
        }
    }
    function updateFocusedAppOrientationAnimated() {
        var mainStageAppIndex = priv.indexOf(priv.mainStageAppId);
        if (mainStageAppIndex >= 0 && mainStageAppIndex < spreadRepeater.count) {
            spreadRepeater.itemAt(mainStageAppIndex).animateToShellOrientation();
        }

        if (priv.sideStageAppId) {
            var sideStageAppIndex = priv.indexOf(priv.sideStageAppId);
            if (sideStageAppIndex >= 0 && sideStageAppIndex < spreadRepeater.count) {
                spreadRepeater.itemAt(sideStageAppIndex).matchShellOrientation();
            }
        }
    }

    orientationChangesEnabled: priv.mainAppOrientationChangesEnabled

    onWidthChanged: {
        spreadView.selectedIndex = -1;
        spreadView.phase = 0;
        spreadView.contentX = -spreadView.shift;
    }

    onShellOrientationChanged: {
        if (shellOrientation == Qt.PortraitOrientation || shellOrientation == Qt.InvertedPortraitOrientation) {
            ApplicationManager.focusApplication(priv.mainStageAppId);
            priv.sideStageAppId = "";
        }
    }

    onInverseProgressChanged: {
        // This can't be a simple binding because that would be triggered after this handler
        // while we need it active before doing the anition left/right
        spreadView.animateX = (inverseProgress == 0)
        if (inverseProgress == 0 && priv.oldInverseProgress > 0) {
            // left edge drag released. Minimum distance is given by design.
            if (priv.oldInverseProgress > units.gu(22)) {
                ApplicationManager.requestFocusApplication("unity8-dash");
            }
        }
        priv.oldInverseProgress = inverseProgress;
    }

    QtObject {
        id: priv
        objectName: "stagesPriv"

        property string focusedAppId: ApplicationManager.focusedApplicationId
        readonly property var focusedAppDelegate: {
            var index = indexOf(focusedAppId);
            return index >= 0 && index < spreadRepeater.count ? spreadRepeater.itemAt(index) : null
        }

        property string oldFocusedAppId: ""
        property bool mainAppOrientationChangesEnabled: false

        property real landscapeHeight: root.orientations.native_ == Qt.LandscapeOrientation ?
                root.nativeHeight : root.nativeWidth

        property bool shellIsLandscape: root.shellOrientation === Qt.LandscapeOrientation
                      || root.shellOrientation === Qt.InvertedLandscapeOrientation

        property string mainStageAppId
        property string sideStageAppId

        onMainStageAppIdChanged: console.log("MAIN STAGE", mainStageAppId)
        onSideStageAppIdChanged: console.log("SIDE STAGE", sideStageAppId)

        // For convenience, keep properties of the first two apps in the model
        property string appId0
        property string appId1

        property int oldInverseProgress: 0

        property QtObject activeMainStageInputWatcher: {
            if (priv.mainStageAppId == "") return null;
            var mainStageAppIndex = priv.indexOf(priv.mainStageAppId);
            return spreadRepeater.itemAt(mainStageAppIndex).surfaceInputWatcher
        }

        onFocusedAppIdChanged: {
            if (priv.focusedAppId.length > 0) {
                var focusedApp = ApplicationManager.findApplication(focusedAppId);
                // STAGE_FIXME
//                if (focusedApp.stage == ApplicationInfoInterface.SideStage) {
//                    priv.sideStageAppId = focusedAppId;
//                } else {
                    priv.mainStageAppId = focusedAppId;
                    root.mainApp = focusedApp;
//                }
            }

            appId0 = ApplicationManager.count >= 1 ? ApplicationManager.get(0).appId : "";
            appId1 = ApplicationManager.count > 1 ? ApplicationManager.get(1).appId : "";
        }

        onFocusedAppDelegateChanged: {
            if (focusedAppDelegate) {
                focusedAppDelegate.focus = true;
            }
        }

        property bool focusedAppDelegateIsDislocated: focusedAppDelegate &&
                                                      (focusedAppDelegate.dragOffset !== 0 || focusedAppDelegate.xTranslateAnimating)
        function indexOf(appId) {
            for (var i = 0; i < ApplicationManager.count; i++) {
                if (ApplicationManager.get(i).appId == appId) {
                    return i;
                }
            }
            return -1;
        }

        function evaluateOneWayFlick(gesturePoints) {
            // Need to have at least 3 points to recognize it as a flick
            if (gesturePoints.length < 3) {
                return false;
            }
            // Need to have a movement of at least 2 grid units to recognize it as a flick
            if (Math.abs(gesturePoints[gesturePoints.length - 1] - gesturePoints[0]) < units.gu(2)) {
                return false;
            }

            var oneWayFlick = true;
            var smallestX = gesturePoints[0];
            var leftWards = gesturePoints[1] < gesturePoints[0];
            for (var i = 1; i < gesturePoints.length; i++) {
                if ((leftWards && gesturePoints[i] >= smallestX)
                        || (!leftWards && gesturePoints[i] <= smallestX)) {
                    oneWayFlick = false;
                    break;
                }
                smallestX = gesturePoints[i];
            }
            return oneWayFlick;
        }

        function getTopApp(stage) {
            // STAGE_FIXME
//            for (var i = 0; i < ApplicationManager.count; i++) {
//                var app = ApplicationManager.get(i)
//                if (app.stage === stage) {
//                    return app;
//                }
//            }
            return null;

        }
    }

    Connections {
        target: ApplicationManager
        onFocusRequested: {
            if (spreadView.interactive) {
                spreadView.snapTo(priv.indexOf(appId));
            } else {
                ApplicationManager.focusApplication(appId);
            }
        }

        onApplicationAdded: {
            if (spreadView.phase == 2) {
                spreadView.snapTo(ApplicationManager.count - 1);
            } else {
                spreadView.phase = 0;
                spreadView.contentX = -spreadView.shift;
                ApplicationManager.focusApplication(appId);
            }
        }

        onApplicationRemoved: {
            if (priv.mainStageAppId == appId) {
                ApplicationManager.focusApplication("unity8-dash")
            }
            if (priv.sideStageAppId == appId) {
                var app = priv.getTopApp(ApplicationInfoInterface.SideStage);
                priv.sideStageAppId = app === null ? "" : app.appId;
            }

            if (ApplicationManager.count == 0) {
                spreadView.phase = 0;
                spreadView.contentX = -spreadView.shift;
            } else if (spreadView.closingIndex == -1) {
                // Unless we're closing the app ourselves in the spread,
                // lets make sure the spread doesn't mess up by the changing app list.
                spreadView.phase = 0;
                spreadView.contentX = -spreadView.shift;

                ApplicationManager.focusApplication(ApplicationManager.get(0).appId);
            }
        }
    }

    Flickable {
        id: spreadView
        objectName: "spreadView"
        anchors.fill: parent
        interactive: (spreadDragArea.dragging || phase > 1) && draggedDelegateCount === 0
        contentWidth: spreadRow.width - shift
        contentX: -shift

        property int tileDistance: units.gu(20)
        property int sideStageWidth: units.gu(40)
        property bool sideStageVisible: priv.sideStageAppId

        // This indicates when the spreadView is active. That means, all the animations
        // are activated and tiles need to line up for the spread.
        readonly property bool active: shiftedContentX > 0 || spreadDragArea.dragging

        // The flickable needs to fill the screen in order to get touch events all over.
        // However, we don't want to the user to be able to scroll back all the way. For
        // that, the beginning of the gesture starts with a negative value for contentX
        // so the flickable wants to pull it into the view already. "shift" tunes the
        // distance where to "lock" the content.
        readonly property real shift: width / 2
        readonly property real shiftedContentX: contentX + shift

        // Phase of the animation:
        // 0: Starting from right edge, a new app (index 1) comes in from the right
        // 1: The app has reached the first snap position.
        // 2: The list is dragged further and snaps into the spread view when entering phase 2
        property int phase

        readonly property int phase0Width: sideStageWidth
        readonly property int phase1Width: sideStageWidth

        // Those markers mark the various positions in the spread (ratio to screen width from right to left):
        // 0 - 1: following finger, snap back to the beginning on release
        readonly property real positionMarker1: 0.2
        // 1 - 2: curved snapping movement, snap to nextInStack on release
        readonly property real positionMarker2: sideStageWidth / spreadView.width
        // 2 - 3: movement follows finger, snaps to phase 2 (full spread) on release
        readonly property real positionMarker3: 0.6
        // passing 3, we detach movement from the finger and snap to phase 2 (full spread)
        readonly property real positionMarker4: 0.8

        readonly property int startSnapPosition: phase0Width * 0.5
        readonly property int endSnapPosition: phase0Width * 0.75
        readonly property real snapPosition: 0.75

        property int selectedIndex: -1
        property int draggedDelegateCount: 0
        property int closingIndex: -1
        property var selectedApplication: selectedIndex !== -1 ? ApplicationManager.get(selectedIndex) : null

        // FIXME: Workaround Flickable's not keepping its contentX still when resized
        onContentXChanged: { forceItToRemainStillIfBeingResized(); }
        onShiftChanged: { forceItToRemainStillIfBeingResized(); }
        function forceItToRemainStillIfBeingResized() {
            if (root.beingResized && contentX != -shift) {
                contentX = -shift;
            }
        }

        property bool animateX: true
        property bool beingResized: root.beingResized
        onBeingResizedChanged: {
            if (beingResized) {
                // Brace yourselves for impact!
                selectedIndex = -1;
                phase = 0;
                contentX = -shift;
            }
        }

        property bool sideStageDragging: sideStage.dragging
        property real sideStageDragProgress: sideStage.progress

        onSideStageDragProgressChanged: {
            if (sideStageDragProgress == 0) {
                ApplicationManager.focusApplication(priv.mainStageAppId);
                priv.sideStageAppId = "";
            } else {
                var app = priv.getTopApp(ApplicationInfoInterface.SideStage);
                priv.sideStageAppId = app === null ? "" : app.appId;
            }
        }

        // In case the ApplicationManager already holds an app when starting up we're missing animations
        // Make sure we end up in the same state
        Component.onCompleted: {
            spreadView.contentX = -spreadView.shift
        }

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
                if (priv.appId0 == priv.mainStageAppId || priv.appId0 == priv.sideStageAppId) {
                    if (priv.appId1 == priv.mainStageAppId || priv.appId1 == priv.sideStageAppId) {
                        return 2;
                    }
                    return 1;
                }
                return 0;
            case "overlay":
                return 1;
            }
            return -1;
        }
        property int nextZInStack: indexToZIndex(nextInStack)

        states: [
            State {
                name: "empty"
            },
            State {
                name: "main"
            },
            State { // Side Stage only in overlay mode
                name: "overlay"
            },
            State { // Main Stage and Side Stage in overlay mode
                name: "mainAndOverlay"
            },
            State { // Main Stage and Side Stage in split mode
                name: "mainAndSplit"
            }
        ]
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
            return "empty";
        }

        onShiftedContentXChanged: {
            if (root.beingResized) {
                // Flickabe.contentX wiggles during resizes. Don't react to it.
                return;
            }
            if (spreadView.phase == 0 && spreadView.shiftedContentX > spreadView.width * spreadView.positionMarker2) {
                spreadView.phase = 1;
            } else if (spreadView.phase == 1 && spreadView.shiftedContentX > spreadView.width * spreadView.positionMarker4) {
                spreadView.phase = 2;
            } else if (spreadView.phase == 1 && spreadView.shiftedContentX < spreadView.width * spreadView.positionMarker2) {
                spreadView.phase = 0;
            }
        }

        function snap() {
            if (shiftedContentX < phase0Width) {
                snapAnimation.targetContentX = -shift;
                snapAnimation.start();
            } else if (shiftedContentX < phase1Width) {
                snapTo(1);
            } else {
                // Add 1 pixel to make sure we definitely hit positionMarker4 even with rounding errors of the animation.
                snapAnimation.targetContentX = spreadView.width * spreadView.positionMarker4 + 1 - shift;
                snapAnimation.start();
            }
        }
        function snapTo(index) {

            console.log("snapTo", index)

            snapAnimation.stop();
            spreadView.selectedIndex = index;
            snapAnimation.targetContentX = -shift;
            snapAnimation.start();
        }

        // We need to shuffle z ordering a bit in order to keep side stage apps above main stage apps.
        // We don't want to really reorder them in the model because that allows us to keep track
        // of the last focused order.
        function indexToZIndex(index) {
            var app = ApplicationManager.get(index);
            if (!app) {
                return index;
            }

            var active = app.appId == priv.mainStageAppId || app.appId == priv.sideStageAppId;
            if (active) /* STAGE_FIXME && app.stage == ApplicationInfoInterface.MainStage) */ {
                // if this app is active, and its the MainStage, always put it to index 0
                return 0;
            }
            // STAGE_FIXME
//            if (active && app.stage == ApplicationInfoInterface.SideStage) {
//                if (!priv.mainStageAppId) {
//                    // Only have SS apps running. Put the active one at 0
//                    return 0;
//                }

//                // Precondition now: There's an active MS app and this is SS app:
//                if (spreadView.nextInStack >= 0 && ApplicationManager.get(spreadView.nextInStack).stage == ApplicationInfoInterface.MainStage) {
//                    // If the next app coming from the right is a MS app, we need to elevate this SS ap above it.
//                    // Put it to at least level 2, or higher if there's more apps coming in before this one.
//                    return Math.max(index, 2);
//                } else {
//                    // if this is no next app to come in from the right, place this one at index 1, just on top the active MS app.
//                    return 1;
//                }
//            }
//            if (index <= 2 && app.stage == ApplicationInfoInterface.MainStage && priv.sideStageAppId) {
//                // Ok, this is an inactive MS app. If there's an active SS app around, we need to place this one
//                // in between the active MS app and the active SS app, so that it comes in from there when dragging from the right.
//                // If there's now active SS app, just leave it where it is.
//                return priv.indexOf(priv.sideStageAppId) < index ? index - 1 : index;
//            }
//            if (index == spreadView.nextInStack && app.stage == ApplicationInfoInterface.SideStage) {
//                // This is a SS app and the next one to come in from the right:
//                if (priv.sideStageAppId && priv.mainStageAppId) {
//                    // If there's both, an active MS and an active SS app, put this one right on top of that
//                    return 2;
//                }
//                // Or if there's only one other active app, put it on top of that.
//                // The case that there isn't any other active app is already handled above.
//                return 1;
//            }
//            if (index == 2 && spreadView.nextInStack == 1 && priv.sideStageAppId) {
//                // If its index 2 but not the next one to come in, it means
//                // we've pulled another one down to index 2. Move this one up to 2 instead.
//                return 3;
//            }
            // don't touch all others... (mostly index > 3 + simple cases where the above doesn't shuffle much)
            return index;
        }

        SequentialAnimation {
            id: snapAnimation
            property int targetContentX: -spreadView.shift

            UbuntuNumberAnimation {
                target: spreadView
                property: "contentX"
                to: snapAnimation.targetContentX
                duration: UbuntuAnimation.FastDuration
            }

            ScriptAction {
                script: {
                    if (spreadView.selectedIndex >= 0) {
                        var newIndex = spreadView.selectedIndex;
                        var application = ApplicationManager.get(newIndex);
                        // STAGE_FIXME
//                        if (application.stage === ApplicationInfoInterface.SideStage) {
//                            sideStage.showNow()
//                        }
                        spreadView.selectedIndex = -1;
                        ApplicationManager.focusApplication(application.appId);
                        spreadView.phase = 0;
                        spreadView.contentX = -spreadView.shift;
                    }
                }
            }
        }

        MouseArea {
            id: spreadRow
            x: spreadView.contentX
            width: spreadView.width + Math.max(spreadView.width, ApplicationManager.count * spreadView.tileDistance)
            height: root.height

            onClicked: {
                spreadView.snapTo(0);
            }

            SideStage {
                id: sideStage
                objectName: "sideStage"
                height: priv.landscapeHeight
                x: spreadView.width - width
                z: {
                    if (priv.sideStageAppId !== "") {
                        return spreadView.indexToZIndex(priv.indexOf(priv.sideStageAppId));
                    }
                    return ApplicationManager.count;
                }

                opacity: spreadView.phase <= 0 ? 1 : 0
                Behavior on opacity { UbuntuNumberAnimation {} }

                InverseMouseArea {
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: parent.width + units.gu(2)
                    enabled: sideStage.enableDragShow
                    onPressed: {
                        // just watching, don't eat!
                        mouse.accepted = false;
                    }
                }
            }

            Repeater {
                id: spreadRepeater
                objectName: "spreadRepeater"
                model: ApplicationManager

                delegate: TransformedTabletSpreadDelegate {
                    id: spreadTile
                    objectName: model.appId ? "tabletSpreadDelegate_" + model.appId
                                            : "tabletSpreadDelegate_null";
                    width: {
                        if (wantsMainStage) {
                            return spreadView.width;
                        } else {
                            return spreadView.sideStageWidth;
                        }
                    }
                    height: {
                        if (wantsMainStage) {
                            return spreadView.height;
                        } else {
                            return priv.landscapeHeight;
                        }
                    }
                    active: model.appId == priv.mainStageAppId || model.appId == priv.sideStageAppId
                    zIndex: selected && wantsMainStage ? 0 : spreadView.indexToZIndex(index)
                    selected: spreadView.selectedIndex == index
                    otherSelected: spreadView.selectedIndex >= 0 && !selected
                    isInSideStage: priv.sideStageAppId === model.appId
                    interactive: !spreadView.interactive && spreadView.phase === 0 && root.interactive
                    swipeToCloseEnabled: spreadView.interactive && !snapAnimation.running
                    maximizedAppTopMargin: root.maximizedAppTopMargin
                    dragOffset: !isDash && model.appId == priv.mainStageAppId && root.inverseProgress > 0 && spreadView.phase === 0 ? root.inverseProgress : 0
                    application: ApplicationManager.get(index)
                    closeable: !isDash

//                    MultiPointTouchArea {
//                        anchors.fill: parent
//                        minimumTouchPoints: 3
//                        maximumTouchPoints: 3
//                        onPressed: {
//                            console.log("PRESSED!");
//                        }
//                        onGestureStarted: {
//                            console.log("GESTURE STARTED!");
//                        }
//                        onTouchUpdated: console.log(touchPoints)
//                    }

                    Binding {
                        target: spreadTile.surfaceInputWatcher
                        property: "eatMoveEvents"
                        value: spreadTile.surfaceInputWatcher.touchPoints.length === 3
                    }

                    readonly property bool wantsMainStage: true /* STAGE_FIXME model.stage == ApplicationInfoInterface.MainStage */

                    readonly property bool isDash: model.appId == "unity8-dash"

                    readonly property bool canSuspend: model.isTouchApp
                            && !isExemptFromLifecycle(model.appId)

                    Binding {
                        target: spreadTile.application
                        property: "requestedState"
                        value: !canSuspend
                                   || (isDash && root.keepDashRunning)
                                   || (!root.suspended && (model.appId == priv.mainStageAppId
                                                           || model.appId == priv.sideStageAppId))
                               ? ApplicationInfoInterface.RequestedRunning
                               : ApplicationInfoInterface.RequestedSuspended
                    }

                    // FIXME: A regular binding doesn't update any more after closing an app.
                    // Using a Binding for now.
                    Binding {
                        target: spreadTile
                        property: "z"
                        value: (!spreadView.active && isDash && !active) ? -1 : spreadTile.zIndex
                    }
                    x: spreadView.width

                    property real behavioredZIndex: zIndex
                    Behavior on behavioredZIndex {
                        enabled: spreadView.closingIndex >= 0
                        UbuntuNumberAnimation {}
                    }

                    // This is required because none of the bindings are triggered in some cases:
                    // When an app is closed, it might happen that ApplicationManager.get(nextInStack)
                    // returns a different app even though the nextInStackIndex and all the related
                    // bindings (index, mainStageApp, sideStageApp, etc) don't change. Let's force a
                    // binding update in that case.
                    Connections {
                        target: ApplicationManager
                        onApplicationRemoved: spreadTile.z = Qt.binding(function() {
                            return spreadView.indexToZIndex(index);
                        })
                    }

                    progress: {
                        var tileProgress = (spreadView.shiftedContentX - behavioredZIndex * spreadView.tileDistance) / spreadView.width;
                        // Some tiles (nextInStack, active) need to move directly from the beginning, normalize progress to immediately start at 0
                        if ((index == spreadView.nextInStack && spreadView.phase < 2) || (active && spreadView.phase < 1)) {
                            tileProgress += behavioredZIndex * spreadView.tileDistance / spreadView.width;
                        }
                        return tileProgress;
                    }

                    // TODO: Hiding tile when progress is such that it will be off screen.
                    property bool occluded: {
                        if (spreadView.active) return false;
                        else if (spreadTile.active) return false;
                        else if (xTranslateAnimating) return false;
                        else if (z <= 1 && priv.focusedAppDelegateIsDislocated) return false;
                        return true;
                    }

                    visible: Powerd.status == Powerd.On &&
                             !greeter.fullyShown &&
                             !occluded

                    animatedProgress: {
                        if (spreadView.phase == 0 && (spreadTile.active || spreadView.nextInStack == index)) {
                            if (progress < spreadView.positionMarker1) {
                                return progress;
                            } else if (progress < spreadView.positionMarker1 + snappingCurve.period) {
                                return spreadView.positionMarker1 + snappingCurve.value * 3;
                            } else {
                                return spreadView.positionMarker2;
                            }
                        }
                        return progress;
                    }

                    shellOrientationAngle: wantsMainStage ? root.shellOrientationAngle : 0
                    shellOrientation: wantsMainStage ? root.shellOrientation : Qt.PortraitOrientation
                    orientations: Orientations {
                        primary: spreadTile.wantsMainStage ? root.orientations.primary : Qt.PortraitOrientation
                        native_: spreadTile.wantsMainStage ? root.orientations.native_ : Qt.PortraitOrientation
                        portrait: root.orientations.portrait
                        invertedPortrait: root.orientations.invertedPortrait
                        landscape: root.orientations.landscape
                        invertedLandscape: root.orientations.invertedLandscape
                    }


                    function getOrientationString(orient) {
                        if (orient==Qt.PortraitOrientation) {
                            return "Portrait";
                        } else if (orient==Qt.LandscapeOrientation) {
                            return "Landscape";
                        } else if (orient==Qt.InvertedLandscapeOrientation) {
                            return "InvertedLandscape";
                        } else if (orient==Qt.InvertedPortraitOrientation) {
                            return "InvertedPortrait";
                        }
                        return "Native";
                    }
                    onShellOrientationAngleChanged: console.log("SHELL ORIENTATION ANGLE", model.appId, root.shellOrientationAngle)
                    onShellOrientationChanged: console.log("SHELL ORIENTATION", model.appId, getOrientationString(root.shellOrientation))
                    onShellPrimaryOrientationChanged: console.log("SHELL PRIMARY ORIENTATION", model.appId, getOrientationString(root.shellPrimaryOrientation))
                    onNativeOrientationChanged: console.log("NATIVE ORIENTATION", model.appId, getOrientationString(root.nativeOrientation))


                    onClicked: {
                        if (spreadView.phase == 2) {
                            spreadView.snapTo(index);
                        }
                    }

                    onDraggedChanged: {
                        if (dragged) {
                            spreadView.draggedDelegateCount++;
                        } else {
                            spreadView.draggedDelegateCount--;
                        }
                    }

                    onClosed: {
                        spreadView.closingIndex = index;
                        ApplicationManager.stopApplication(ApplicationManager.get(index).appId);
                    }

                    onFocusChanged: {
                        if (focus && ApplicationManager.focusedApplicationId !== model.appId) {
                            ApplicationManager.focusApplication(model.appId);
                        }

                        // STAGE_FIXME
//                        if (focus && model.stage === ApplicationInfoInterface.SideStage) {
//                            sideStage.show();
//                        }
                    }

                    Binding {
                        target: root
                        when: model.appId == priv.mainStageAppId
                        property: "mainAppWindowOrientationAngle"
                        value: appWindowOrientationAngle
                    }
                    Binding {
                        target: priv
                        when: model.appId == priv.mainStageAppId
                        property: "mainAppOrientationChangesEnabled"
                        value: orientationChangesEnabled
                    }

                    EasingCurve {
                        id: snappingCurve
                        type: EasingCurve.Linear
                        period: (spreadView.positionMarker2 - spreadView.positionMarker1) / 3
                        progress: spreadTile.progress - spreadView.positionMarker1
                    }
                }
            }
        }
    }

    Connections {
        id: triDragInputSurfaceConnector
        target: priv.activeMainStageInputWatcher

        property bool triPress: false
        property bool wasDragging: false
        property bool wasShown: false
        onTargetChanged: {
            triPress = false;
            wasDragging = false;
        }

        onPressed: {
            wasShown = false;
            if (target.touchPoints.length === 3) {
                if (!sideStage.shown) {
                    sideStage.show();
                    wasShown = true;
                }
                triPress = true;
                console.log("PRESSED", triPress)
            } else {
                triPress = false;
            }
        }
        onUpdated: {
            for (var i = 0; i < target.touchPoints.length; i++) {
                var tp = target.touchPoints[i];
//                console.log("updated: (x=" + tp.x + ", y="+tp.y + ") - dragging=" + tp.dragging);
            }
        }
        onDraggingChanged: {
            console.log("dragging", target.dragging)
            if (dragging) {
                wasDragging = true;
            }
        }
        onReleased: {
            if (target.touchPoints.length === 0) {
                if (triPress && !wasDragging) {
                    if (sideStage.shown && !wasShown) {
                        sideStage.hide();
                        wasShown = false;
                    }
                }
                triPress = false;
                wasDragging = false;
                console.log("RELEASED", triPress)
            }
        }
    }

    Rectangle {
        color: "red"
        visible: triDragInputSurfaceConnector.triPress
        x: {
            if (priv.activeMainStageInputWatcher == null) return 0;

            var sum = 0
            for (var i = 0; i < priv.activeMainStageInputWatcher.touchPoints.length; i++) {
                sum += root.mapFromItem(priv.activeMainStageInputWatcher.target, priv.activeMainStageInputWatcher.touchPoints[i].x, 0).x;
            }
            return sum/priv.activeMainStageInputWatcher.touchPoints.length - width/2;
        }
        y: {
            if (priv.activeMainStageInputWatcher == null) return 0;

            var sum = 0
            for (var i = 0; i < priv.activeMainStageInputWatcher.touchPoints.length; i++) {
                sum += root.mapFromItem(priv.activeMainStageInputWatcher.target, 0, priv.activeMainStageInputWatcher.touchPoints[i].y).y;
            }
            return sum/priv.activeMainStageInputWatcher.touchPoints.length - height/2;
        }

        width: units.gu(5)
        height: units.gu(5)
    }

    //eat touch events during the right edge gesture
    MouseArea {
        anchors.fill: parent
        enabled: spreadDragArea.dragging
    }

    DirectionalDragArea {
        id: spreadDragArea
        objectName: "spreadDragArea"
        x: parent.width - root.dragAreaWidth
        anchors { top: parent.top; bottom: parent.bottom }
        width: root.dragAreaWidth
        direction: Direction.Leftwards
        enabled: (spreadView.phase != 2 && root.spreadEnabled) || dragging

        property var gesturePoints: new Array()

        onTouchXChanged: {
            if (!dragging) {
                spreadView.phase = 0;
                spreadView.contentX = -spreadView.shift;
            }

            if (dragging) {
                var dragX = -touchX + spreadDragArea.width - spreadView.shift;
                var maxDrag = spreadView.width * spreadView.positionMarker4 - spreadView.shift;
                spreadView.contentX = Math.min(dragX, maxDrag);
            }
            gesturePoints.push(touchX);
        }

        onDraggingChanged: {
            if (dragging) {
                // Gesture recognized. Start recording this gesture
                gesturePoints = [];
            } else {
                // Ok. The user released. Find out if it was a one-way movement.
                var oneWayFlick = priv.evaluateOneWayFlick(gesturePoints);
                gesturePoints = [];

                if (oneWayFlick && spreadView.shiftedContentX < spreadView.positionMarker1 * spreadView.width) {
                    // If it was a short one-way movement, do the Alt+Tab switch
                    // no matter if we didn't cross positionMarker1 yet.
                    spreadView.snapTo(spreadView.nextInStack);
                } else {
                    if (spreadView.shiftedContentX < spreadView.width * spreadView.positionMarker1) {
                        spreadView.snap();
                    } else if (spreadView.shiftedContentX < spreadView.width * spreadView.positionMarker2) {
                        spreadView.snapTo(spreadView.nextInStack);
                    } else {
                        // otherwise snap to the closest snap position we can find
                        // (might be back to start, to app 1 or to spread)
                        spreadView.snap();
                    }
                }
            }
        }
    }
}
