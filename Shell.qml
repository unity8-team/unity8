/*
 * Copyright (C) 2013 Canonical, Ltd.
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
import Ubuntu.Components 0.1
import LightDM 0.1 as LightDM
import "Dash"
import "Greeter"
import "Launcher"
import "Panel"
import "Hud"
import "Components"
import "Components/Math.js" as MathLocal
import "Bottombar"
import "Stages"

FocusScope {
    id: shell

    // this is only here to select the width / height of the window if not running fullscreen
    property bool tablet: false
    width: tablet ? units.gu(160) : units.gu(40)
    height: tablet ? units.gu(100) : units.gu(71)

    property real edgeSize: units.gu(2)
    property url default_background: shell.width >= units.gu(60) ? "graphics/tablet_background.jpg" : "graphics/phone_background.jpg"
    property url background: default_background
    readonly property real panelHeight: panel.panelHeight

    property bool dashShown: dash.shown
    readonly property bool stageScreenshotsReady: stageManager.stageScreenshotsReady

    property ListModel searchHistory: SearchHistoryModel {}

    property var applicationManager: ApplicationManagerWrapper {}

    function activateApplication(desktopFile, argument) {
        stageManager.activateApplication(desktopFile, argument);
    }

    VolumeControl {
        id: volumeControl
    }

    Keys.onVolumeUpPressed: volumeControl.volumeUp()
    Keys.onVolumeDownPressed: volumeControl.volumeDown()

    Keys.onReleased: {
        if (event.key == Qt.Key_PowerOff) {
            greeter.show()
        }
    }

    Item {
        id: underlay

        anchors.fill: parent
        visible: !(panel.indicators.fullyOpened && shell.width <= panel.indicatorsMenuWidth)
                 && stageManager.needUnderlay

        Image {
            id: backgroundImage
            source: shell.background
            sourceSize.width: parent.width
            sourceSize.height: parent.height
            anchors.fill: parent
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: dash.disappearingAnimationProgress
        }

        Dash {
            id: dash

            available: !greeter.shown
            hides: [stageManager, launcher, panel.indicators]
            shown: disappearingAnimationProgress !== 1.0
            enabled: disappearingAnimationProgress === 0.0
            // FIXME: unfocus all applications when going back to the dash
            onEnabledChanged: {
                if (enabled) {
                    shell.applicationManager.unfocusCurrentApplication()
                }
            }

            anchors {
                fill: parent
                topMargin: panel.panelHeight
            }

            contentScale: 1.0 - 0.2 * disappearingAnimationProgress
            opacity: 1.0 - disappearingAnimationProgress
            property real disappearingAnimationProgress: ((greeter.shown) ? greeterRevealer.animatedProgress : stageManager.animatedProgress)
            // FIXME: only necessary because stageManager.animatedProgress and
            // greeterRevealer.animatedProgress are not animated
            Behavior on disappearingAnimationProgress { SmoothedAnimation { velocity: 5 }}
        }
    }

    StageManager {
        id: stageManager

        anchors.fill: parent

        enabled: !greeter.shown
        hides: [launcher, panel.indicators]
        applicationManager: shell.applicationManager
        leftSwipePosition: launcher.progress
        panelHeight: panel.panelHeight
        edgeHandleSize: shell.edgeSize
    }

    Greeter {
        id: greeter

        available: true
        hides: [launcher, panel.indicators, hud]
        shown: true
        showAnimation: StandardAnimation { property: "x"; to: greeterRevealer.openedValue }
        hideAnimation: StandardAnimation { property: "x"; to: greeterRevealer.closedValue }

        y: panel.panelHeight
        width: parent.width
        height: parent.height - panel.panelHeight

        property var previousMainApp: null
        property var previousSideApp: null

        onShownChanged: {
            if (shown) {
                greeter.forceActiveFocus();
                // FIXME: *FocusedApplication are not updated when unfocused, hence the need to check whether
                // the stage was actually shown
                if (stageManager.mainStageFullyShown) greeter.previousMainApp = applicationManager.mainStageFocusedApplication;
                if (stageManager.sideStageFullyShown) greeter.previousSideApp = applicationManager.sideStageFocusedApplication;
                applicationManager.unfocusCurrentApplication();
            } else {
                if (greeter.previousMainApp) {
                    applicationManager.focusApplication(greeter.previousMainApp);
                    greeter.previousMainApp = null;
                }
                if (greeter.previousSideApp) {
                    applicationManager.focusApplication(greeter.previousSideApp);
                    greeter.previousSideApp = null;
                }
            }
        }

        onUnlocked: greeter.hide()
        onSelected: {
            var bgPath = greeter.model.data(uid, LightDM.UserRoles.BackgroundPathRole)
            shell.background = bgPath ? bgPath : default_background
        }
    }

    InputFilterArea {
        anchors.fill: parent
        blockInput: greeter.shown
    }

    Revealer {
        id: greeterRevealer

        property real animatedProgress: MathLocal.clamp(-dragPosition / closedValue, 0, 1)
        target: greeter
        width: greeter.width
        height: greeter.height
        handleSize: shell.edgeSize
        orientation: Qt.Horizontal
        visible: greeter.shown
        enabled: !greeter.locked
    }

    Item {
        id: overlay

        anchors.fill: parent

        Panel {
            id: panel
            anchors.fill: parent //because this draws indicator menus
            indicatorsMenuWidth: parent.width > units.gu(60) ? units.gu(40) : parent.width
            indicators {
                hides: [launcher]
            }
            fullscreenMode: stageManager.fullscreenMode
            searchVisible: !greeter.shown

            InputFilterArea {
                anchors.fill: parent
                blockInput: panel.indicators.shown
            }
        }

        Hud {
            id: hud

            width: parent.width > units.gu(60) ? units.gu(40) : parent.width
            height: parent.height

            available: !greeter.shown && !panel.indicators.shown
            shown: false
            showAnimation: StandardAnimation { property: "y"; duration: hud.showableAnimationDuration; to: 0; easing.type: Easing.Linear }
            hideAnimation: StandardAnimation { property: "y"; duration: hud.showableAnimationDuration; to: hudRevealer.closedValue; easing.type: Easing.Linear }

            Connections {
                target: shell.applicationManager
                onMainStageFocusedApplicationChanged: hud.hide()
                onSideStageFocusedApplicationChanged: hud.hide()
            }

            InputFilterArea {
                anchors.fill: parent
                blockInput: hud.shown
            }
        }

        Revealer {
            id: hudRevealer

            enabled: hud.shown
            width: hud.width
            anchors.left: hud.left
            height: parent.height
            target: hud.revealerTarget
            closedValue: height
            openedValue: 0
            direction: Qt.RightToLeft
            orientation: Qt.Vertical
            handleSize: hud.handleHeight
            onCloseClicked: target.hide()
        }

        Bottombar {
            theHud: hud
            anchors.fill: parent
            enabled: !panel.indicators.shown
        }

        InputFilterArea {
            blockInput: launcher.shown
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
            }
            width: launcher.width
        }

        Launcher {
            id: launcher

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width
            dragAreaWidth: shell.edgeSize
            available: !greeter.locked
            teasing: available && greeter.leftTeaserPressed
            onDashItemSelected: {
                greeter.hide()
                // Animate if moving between application and dash
                if (!stageManager.shown) {
                    dash.setCurrentLens("home.lens", true, false)
                } else {
                    dash.setCurrentLens("home.lens", false, false)
                }
                stageManager.hide();
            }
            onDash: {
                dash.setCurrentLens("applications.lens", true, false)
                stageManager.hide();
            }
            onLauncherApplicationSelected:{
                greeter.hide()
                shell.activateApplication(desktopFile)
            }
            onShownChanged: {
                if (shown) {
                    panel.indicators.hide()
                    hud.hide()
                }
            }
        }
    }

    focus: true

    InputFilterArea {
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }
        width: shell.edgeSize
        blockInput: true
    }

    InputFilterArea {
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }
        width: shell.edgeSize
        blockInput: true
    }

    Binding {
        target: i18n
        property: "domain"
        value: "unity8"
    }

    //FIXME: This should be handled in the input stack, keyboard shouldnt propagate
    MouseArea {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: shell.applicationManager ? shell.applicationManager.keyboardHeight : 0

        enabled: shell.applicationManager && shell.applicationManager.keyboardVisible
    }
}
