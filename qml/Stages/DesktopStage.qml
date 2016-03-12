/*
 * Copyright (C) 2014-2016 Canonical, Ltd.
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
import Unity.Application 0.1
import "../Components/PanelState"
import "../Components"
import Utils 0.1
import Ubuntu.Gestures 0.1
import GlobalShortcut 1.0

AbstractStage {
    id: root
    anchors.fill: parent

    // functions to be called from outside
    function updateFocusedAppOrientation() { /* TODO */ }
    function updateFocusedAppOrientationAnimated() { /* TODO */}
    function pushRightEdge(amount) {
        if (spread.state === "") {
            edgeBarrier.push(amount);
        }
    }

    mainApp: ApplicationManager.focusedApplicationId
            ? ApplicationManager.findApplication(ApplicationManager.focusedApplicationId)
            : null

    // application windows never rotate independently
    mainAppWindowOrientationAngle: shellOrientationAngle

    orientationChangesEnabled: true

    Connections {
        target: ApplicationManager
        onApplicationAdded: {
            if (spread.state == "altTab") {
                spread.state = "";
            }

            ApplicationManager.focusApplication(appId);
        }

        onApplicationRemoved: {
            priv.focusNext();
        }

        onFocusRequested: {
            var delegate = priv.appDelegate(appId);
            if (delegate) {
                delegate.restore();
            } else { // app died, start it
                ApplicationManager.startApplication(appId);
            }

            if (spread.state == "altTab") {
                spread.cancel();
            }
        }

        onStopRequested: {
            var delegate = priv.appDelegate(appId);
            if (delegate) {
                delegate.close();
            }
        }
    }

    GlobalShortcut {
        id: closeWindowShortcut
        shortcut: Qt.AltModifier|Qt.Key_F4
        onTriggered: priv.focusedAppDelegate.close()
        active: priv.focusedAppId !== ""
    }

    GlobalShortcut {
        id: showSpreadShortcut
        shortcut: Qt.MetaModifier|Qt.Key_W
        onTriggered: spread.state = "altTab"
    }

    GlobalShortcut {
        id: minimizeAllShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_D
        onTriggered: priv.minimizeAllWindows()
    }

    GlobalShortcut {
        id: maximizeWindowShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_Up
        onTriggered: priv.focusedAppDelegate.maximize()
        active: priv.focusedAppDelegate !== null
    }

    GlobalShortcut {
        id: maximizeWindowLeftShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_Left
        onTriggered: priv.focusedAppDelegate.maximizeLeft()
        active: priv.focusedAppDelegate !== null
    }

    GlobalShortcut {
        id: maximizeWindowRightShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_Right
        onTriggered: priv.focusedAppDelegate.maximizeRight()
        active: priv.focusedAppDelegate !== null
    }

    GlobalShortcut {
        id: minimizeRestoreShortcut
        shortcut: Qt.MetaModifier|Qt.ControlModifier|Qt.Key_Down
        onTriggered: priv.focusedAppDelegate.maximized || priv.focusedAppDelegate.maximizedLeft || priv.focusedAppDelegate.maximizedRight ||
                     priv.focusedAppDelegate.maximizedHorizontally || priv.focusedAppDelegate.maximizedVertically
                     ? priv.focusedAppDelegate.restoreFromMaximized() : priv.focusedAppDelegate.minimize()
        active: priv.focusedAppDelegate !== null
    }

    QtObject {
        id: priv

        readonly property string focusedAppId: ApplicationManager.focusedApplicationId
        readonly property var focusedAppDelegate: {
            var index = indexOf(focusedAppId);
            return index >= 0 && index < appRepeater.count ? appRepeater.itemAt(index) : null
        }
        onFocusedAppDelegateChanged: updateForegroundMaximizedApp();

        property int foregroundMaximizedAppZ: -1
        property int foregroundMaximizedAppIndex: -1 // for stuff like drop shadow and focusing maximized app by clicking panel

        function updateForegroundMaximizedApp() {
            var tmp = -1;
            var tmpAppId = -1;
            for (var i = appRepeater.count - 1; i >= 0; i--) {
                var item = appRepeater.itemAt(i);
                if (item && item.visuallyMaximized) {
                    tmpAppId = i;
                    tmp = Math.max(tmp, item.normalZ);
                }
            }
            foregroundMaximizedAppZ = tmp;
            foregroundMaximizedAppIndex = tmpAppId;
        }

        function indexOf(appId) {
            for (var i = 0; i < ApplicationManager.count; i++) {
                if (ApplicationManager.get(i).appId == appId) {
                    return i;
                }
            }
            return -1;
        }

        function minimizeAllWindows() {
            for (var i = 0; i < appRepeater.count; i++) {
                var appDelegate = appRepeater.itemAt(i);
                if (appDelegate && !appDelegate.minimized) {
                    appDelegate.minimize();
                }
            }

            ApplicationManager.unfocusCurrentApplication(); // no app should have focus at this point
        }

        function focusNext() {
            ApplicationManager.unfocusCurrentApplication();
            for (var i = 0; i < appRepeater.count; i++) {
                var appDelegate = appRepeater.itemAt(i);
                if (appDelegate && !appDelegate.minimized) {
                    ApplicationManager.focusApplication(appDelegate.appId);
                    return;
                }
            }
        }

        function appDelegate(appId) {
            var appIndex = indexOf(appId);
            return appRepeater.itemAt(appIndex);
        }
    }

    Connections {
        target: PanelState
        onClose: if (priv.focusedAppDelegate) {
                     priv.focusedAppDelegate.close()
                 }
        onMinimize: priv.focusedAppDelegate && priv.focusedAppDelegate.minimize();
        onMaximize: priv.focusedAppDelegate // don't restore minimized apps when double clicking the panel
                    && priv.focusedAppDelegate.restoreFromMaximized();
        onFocusMaximizedApp: if (priv.foregroundMaximizedAppIndex != -1) {
                                 ApplicationManager.focusApplication(appRepeater.itemAt(priv.foregroundMaximizedAppIndex).appId);
                             }
    }

    Binding {
        target: PanelState
        property: "buttonsVisible"
        value: priv.focusedAppDelegate !== null && priv.focusedAppDelegate.maximized // FIXME for Locally integrated menus
               && spread.state == ""
    }

    Binding {
        target: PanelState
        property: "title"
        value: {
            if (priv.focusedAppDelegate !== null && spread.state == "") {
                if (priv.focusedAppDelegate.maximized)
                    return priv.focusedAppDelegate.title
                else
                    return priv.focusedAppDelegate.appName
            }
            return ""
        }
        when: priv.focusedAppDelegate
    }

    Binding {
        target: PanelState
        property: "dropShadow"
        value: priv.focusedAppDelegate && !priv.focusedAppDelegate.maximized && priv.foregroundMaximizedAppIndex !== -1
    }

    Component.onDestruction: {
        PanelState.title = "";
        PanelState.buttonsVisible = false;
        PanelState.dropShadow = false;
    }


    FocusScope {
        id: appContainer
        objectName: "appContainer"
        anchors.fill: parent
        focus: spread.state !== "altTab"

        CrossFadeImage {
            id: wallpaper
            anchors.fill: parent
            source: root.background
            sourceSize { height: root.height; width: root.width }
            fillMode: Image.PreserveAspectCrop
        }

        Repeater {
            id: appRepeater
            model: ApplicationManager
            objectName: "appRepeater"

            delegate: FocusScope {
                id: appDelegate
                objectName: "appDelegate_" + appId
                // z might be overriden in some cases by effects, but we need z ordering
                // to calculate occlusion detection
                property int normalZ: ApplicationManager.count - index
                z: normalZ
                y: PanelState.panelHeight
                focus: appId === priv.focusedAppId
                width: decoratedWindow.width
                height: decoratedWindow.height
                property alias requestedWidth: decoratedWindow.requestedWidth
                property alias requestedHeight: decoratedWindow.requestedHeight
                property alias minimumWidth: decoratedWindow.minimumWidth
                property alias minimumHeight: decoratedWindow.minimumHeight
                property alias maximumWidth: decoratedWindow.maximumWidth
                property alias maximumHeight: decoratedWindow.maximumHeight
                property alias widthIncrement: decoratedWindow.widthIncrement
                property alias heightIncrement: decoratedWindow.heightIncrement

                readonly property bool maximized: windowState & WindowStateStorage.WindowStateMaximized
                readonly property bool maximizedLeft: windowState & WindowStateStorage.WindowStateMaximizedLeft
                readonly property bool maximizedRight: windowState & WindowStateStorage.WindowStateMaximizedRight
                readonly property bool maximizedHorizontally: windowState & WindowStateStorage.WindowStateMaximizedHorizontally
                readonly property bool maximizedVertically: windowState & WindowStateStorage.WindowStateMaximizedVertically
                readonly property bool minimized: windowState & WindowStateStorage.WindowStateMinimized
                readonly property alias fullscreen: decoratedWindow.fullscreen
                property int windowState: WindowStateStorage.WindowStateNormal

                readonly property string appId: model.appId
                property bool animationsEnabled: true
                property alias title: decoratedWindow.title
                readonly property string appName: model.name
                property bool visuallyMaximized: false
                property bool visuallyMinimized: false

                readonly property alias appWindow: decoratedWindow.window

                onFocusChanged: {
                    if (focus && ApplicationManager.focusedApplicationId !== appId) {
                        ApplicationManager.focusApplication(appId);
                    }
                }

                onVisuallyMaximizedChanged: priv.updateForegroundMaximizedApp()

                visible: !visuallyMinimized &&
                         !greeter.fullyShown &&
                         (priv.foregroundMaximizedAppZ === -1 || priv.foregroundMaximizedAppZ <= z) ||
                         decoratedWindow.fullscreen ||
                         (spread.state == "altTab" && index === spread.highlightedIndex)

                Binding {
                    target: ApplicationManager.get(index)
                    property: "requestedState"
                    // TODO: figure out some lifecycle policy, like suspending minimized apps
                    //       if running on a tablet or something.
                    // TODO: If the device has a dozen suspended apps because it was running
                    //       in staged mode, when it switches to Windowed mode it will suddenly
                    //       resume all those apps at once. We might want to avoid that.
                    value: ApplicationInfoInterface.RequestedRunning // Always running for now
                }

                function maximize(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    windowState = WindowStateStorage.WindowStateMaximized;
                }
                function maximizeLeft() {
                    windowState = WindowStateStorage.WindowStateMaximizedLeft;
                }
                function maximizeRight() {
                    windowState = WindowStateStorage.WindowStateMaximizedRight;
                }
                function maximizeHorizontally() {
                    windowState = WindowStateStorage.WindowStateMaximizedHorizontally;
                }
                function maximizeVertically() {
                    windowState = WindowStateStorage.WindowStateMaximizedVertically;
                }
                function minimize(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    windowState |= WindowStateStorage.WindowStateMinimized; // add the minimized bit
                }
                function restoreFromMaximized(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    windowState = WindowStateStorage.WindowStateNormal;
                }
                function restore(animated) {
                    animationsEnabled = (animated === undefined) || animated;
                    windowState &= ~WindowStateStorage.WindowStateMinimized; // clear the minimized bit
                    if (maximized)
                        maximize();
                    else if (maximizedLeft)
                        maximizeLeft();
                    else if (maximizedRight)
                        maximizeRight();
                    else if (maximizedHorizontally)
                        maximizeHorizontally();
                    else if (maximizedVertically)
                        maximizeVertically();
                    ApplicationManager.focusApplication(appId);
                }

                function close() {
                    state = "closing";
                }

                function playFocusAnimation() {
                    focusAnimation.start()
                }

                UbuntuNumberAnimation {
                    id: focusAnimation
                    target: appDelegate
                    property: "scale"
                    from: 0.98
                    to: 1
                    duration: UbuntuAnimation.SnapDuration
                }

                states: [
                    State {
                        name: "closing"
                        PropertyChanges { // freeze the values
                            target: appDelegate; explicit: true; restoreEntryValues: false;
                            x: appDelegate.x; y: appDelegate.y
                            requestedWidth: appDelegate.width; requestedHeight: appDelegate.height
                        }
                    },
                    State {
                        name: "fullscreen"; when: decoratedWindow.fullscreen
                        PropertyChanges {
                            target: appDelegate;
                            x: 0; y: -PanelState.panelHeight
                            requestedWidth: appContainer.width; requestedHeight: appContainer.height;
                        }
                    },
                    State {
                        name: "normal";
                        when: appDelegate.windowState == WindowStateStorage.WindowStateNormal
                        PropertyChanges {
                            target: appDelegate;
                            visuallyMinimized: false;
                            visuallyMaximized: false;
                            opacity: 1; scale: 1
                        }
                    },
                    State {
                        name: "maximized"; when: appDelegate.maximized && !appDelegate.minimized
                        PropertyChanges {
                            target: appDelegate;
                            x: root.leftMargin; y: 0;
                            requestedWidth: appContainer.width - root.leftMargin; requestedHeight: appContainer.height;
                            visuallyMinimized: false;
                            visuallyMaximized: true;
                            opacity: 1; scale: 1
                        }
                    },
                    State {
                        name: "maximizedLeft"; when: appDelegate.maximizedLeft && !appDelegate.minimized
                        PropertyChanges { target: appDelegate; x: root.leftMargin; y: PanelState.panelHeight;
                            requestedWidth: (appContainer.width - root.leftMargin)/2; requestedHeight: appContainer.height - PanelState.panelHeight }
                    },
                    State {
                        name: "maximizedRight"; when: appDelegate.maximizedRight && !appDelegate.minimized
                        PropertyChanges { target: appDelegate; x: (appContainer.width + root.leftMargin)/2; y: PanelState.panelHeight;
                            requestedWidth: (appContainer.width - root.leftMargin)/2; requestedHeight: appContainer.height - PanelState.panelHeight }
                    },
                    State {
                        name: "maximizedHorizontally"; when: appDelegate.maximizedHorizontally && !appDelegate.minimized
                        PropertyChanges { target: appDelegate; x: root.leftMargin; requestedWidth: appContainer.width - root.leftMargin }
                    },
                    State {
                        name: "maximizedVertically"; when: appDelegate.maximizedVertically && !appDelegate.minimized
                        PropertyChanges { target: appDelegate; y: PanelState.panelHeight; requestedHeight: appContainer.height - PanelState.panelHeight }
                    },
                    State {
                        name: "minimized"; when: appDelegate.minimized
                        PropertyChanges {
                            target: appDelegate;
                            x: -appDelegate.width / 2;
                            scale: units.gu(5) / appDelegate.width;
                            opacity: 0;
                            visuallyMinimized: true;
                            visuallyMaximized: false
                        }
                    }
                ]
                transitions: [
                    Transition {
                        from: ",minimized"
                        to: "normal"
                        enabled: appDelegate.animationsEnabled
                        PropertyAction { target: appDelegate; properties: "visuallyMinimized,visuallyMaximized" }
                        UbuntuNumberAnimation { target: appDelegate; properties: "x,y" }
                        UbuntuNumberAnimation {
                            target: appDelegate
                            property: 'scale'
                            from: 0.85
                            to: 1
                            duration: UbuntuAnimation.SnapDuration
                        }
                        UbuntuNumberAnimation {
                            target: appDelegate
                            property: 'opacity'
                            from: 0
                            to: 1
                            duration: UbuntuAnimation.SnapDuration
                        }
                    },
                    Transition {
                        to: "minimized"
                        enabled: appDelegate.animationsEnabled
                        PropertyAction { target: appDelegate; property: "visuallyMaximized" }
                        SequentialAnimation {
                            UbuntuNumberAnimation { target: appDelegate; properties: "x,y,opacity,scale,requestedWidth,requestedHeight" }
                            PropertyAction { target: appDelegate; property: "visuallyMinimized" }
                            ScriptAction {
                                script: {
                                    if (appDelegate.minimized) {
                                        priv.focusNext();
                                    }
                                }
                            }
                        }
                    },
                    Transition {
                        to: "closing"
                        SequentialAnimation {
                            PropertyAction { target: appDelegate; properties: "x,y,requestedWidth,requestedHeight" }
                            ParallelAnimation {
                                UbuntuNumberAnimation {
                                    target: appDelegate
                                    property: 'scale'
                                    from: 1
                                    to: 0.85
                                    duration: UbuntuAnimation.SnapDuration
                                    easing: UbuntuAnimation.StandardEasingReverse
                                }
                                UbuntuNumberAnimation {
                                    target: appDelegate
                                    property: 'opacity'
                                    from: 1
                                    to: 0
                                    duration: UbuntuAnimation.SnapDuration
                                    easing: UbuntuAnimation.StandardEasingReverse
                                }
                            }
                            // hack: make sure the animation has really finished before closing the app
                            PauseAnimation { duration: UbuntuAnimation.SnapDuration }
                            ScriptAction {
                                script: {
                                    ApplicationManager.stopApplication(appId);
                                }
                            }
                        }
                    },
                    Transition {
                        from: "minimized"
                        to: "closing"
                        ScriptAction {
                            script: {
                                ApplicationManager.stopApplication(appId);
                            }
                        }
                    },
                    Transition {
                        to: "*" //maximized and fullscreen
                        enabled: appDelegate.animationsEnabled
                        PropertyAction { target: appDelegate; property: "visuallyMinimized" }
                        SequentialAnimation {
                            UbuntuNumberAnimation { target: appDelegate; properties: "x,y,opacity,scale,requestedWidth,requestedHeight" }
                            PropertyAction { target: appDelegate; property: "visuallyMaximized" }
                        }
                    }
                ]

                Binding {
                    id: previewBinding
                    target: appDelegate
                    property: "z"
                    value: ApplicationManager.count + 1
                    when: index == spread.highlightedIndex && spread.ready
                }

                WindowResizeArea {
                    objectName: "windowResizeArea"
                    target: appDelegate
                    minWidth: units.gu(10)
                    minHeight: units.gu(10)
                    borderThickness: units.gu(2)
                    windowId: model.appId // FIXME: Change this to point to windowId once we have such a thing
                    screenWidth: appContainer.width
                    screenHeight: appContainer.height
                    leftMargin: root.leftMargin

                    onPressed: { ApplicationManager.focusApplication(model.appId) }
                }

                DecoratedWindow {
                    id: decoratedWindow
                    objectName: "decoratedWindow"
                    anchors.left: appDelegate.left
                    anchors.top: appDelegate.top
                    application: ApplicationManager.get(index)
                    active: ApplicationManager.focusedApplicationId === model.appId
                    focus: true

                    onClose: appDelegate.close()
                    onMaximize: appDelegate.maximized || appDelegate.maximizedLeft || appDelegate.maximizedRight
                                || appDelegate.maximizedHorizontally || appDelegate.maximizedVertically
                                ? appDelegate.restoreFromMaximized() : appDelegate.maximize()
                    onMaximizeHorizontally: appDelegate.maximizedHorizontally ? appDelegate.restoreFromMaximized() : appDelegate.maximizeHorizontally()
                    onMaximizeVertically: appDelegate.maximizedVertically ? appDelegate.restoreFromMaximized() : appDelegate.maximizeVertically()
                    onMinimize: appDelegate.minimize()
                    onDecorationPressed: { ApplicationManager.focusApplication(model.appId) }
                }
            }
        }
    }

    EdgeBarrier {
        id: edgeBarrier

        // NB: it does its own positioning according to the specified edge
        edge: Qt.RightEdge

        onPassed: { spread.show(); }
        material: Component {
            Item {
                Rectangle {
                    width: parent.height
                    height: parent.width
                    rotation: 90
                    anchors.centerIn: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(0.16,0.16,0.16,0.5)}
                        GradientStop { position: 1.0; color: Qt.rgba(0.16,0.16,0.16,0)}
                    }
                }
            }
        }
    }

    DirectionalDragArea {
        direction: Direction.Leftwards
        anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
        width: units.gu(1)
        onDraggingChanged: { if (dragging) { spread.show(); } }
    }

    DesktopSpread {
        id: spread
        objectName: "spread"
        anchors.fill: appContainer
        workspace: appContainer
        focus: state == "altTab"
        altTabPressed: root.altTabPressed

        onPlayFocusAnimation: {
            appRepeater.itemAt(index).playFocusAnimation();
        }
    }
}
