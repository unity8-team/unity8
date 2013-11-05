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
import AccountsService 0.1
import GSettings 1.0
import Unity.Application 0.1
import Ubuntu.Components 0.1
import Ubuntu.Gestures 0.1
import SessionBroadcast 0.1
import "Dash"
import "Panel"
import "Components"
import "Components/Math.js" as MathLocal

FocusScope {
    id: shell

    // this is only here to select the width / height of the window if not running fullscreen
    property bool tablet: false
    width: tablet ? units.gu(160) : applicationArguments.hasGeometry() ? applicationArguments.width() : units.gu(40)
    height: tablet ? units.gu(100) : applicationArguments.hasGeometry() ? applicationArguments.height() : units.gu(71)

    property real edgeSize: units.gu(2)
    property url defaultBackground: shell.width >= units.gu(60) ? "graphics/tablet_background.jpg" : "graphics/phone_background.jpg"
    property url background
    readonly property real panelHeight: panel.panelHeight

    property bool dashShown: dash.shown

    property ListModel searchHistory: SearchHistoryModel {}

    property var applicationManager: ApplicationManagerWrapper {}

    Component.onCompleted: {
        Theme.name = "Ubuntu.Components.Themes.SuruGradient"

        applicationManager.sideStageEnabled = false;

        // FIXME: if application focused before shell starts, shell draws on top of it only.
        // We should detect already running applications on shell start and bring them to the front.
        applicationManager.unfocusCurrentApplication();
    }

    readonly property bool applicationFocused: false
    // Used for autopilot testing.
    readonly property string currentFocusedAppId: ApplicationManager.focusedApplicationId

    readonly property bool fullscreenMode: {
        if (greeter.shown || lockscreen.shown) {
            return false;
        } else if (mainStage.usingScreenshots) { // Window Manager animating so want to re-evaluate fullscreen mode
            return mainStage.switchingFromFullscreenToFullscreen;
        } else if (applicationManager.mainStageFocusedApplication) {
            return applicationManager.mainStageFocusedApplication.fullscreen;
        } else {
            return false;
        }
    }

    function activateApplication(desktopFile, argument) {
        if (applicationManager) {
            // For newly started applications, as it takes them time to draw their first frame
            // we add a delay before we hide the animation screenshots to compensate.
            var addDelay = !applicationManager.getApplicationFromDesktopFile(desktopFile);

            var application;
            application = applicationManager.activateApplication(desktopFile, argument);
            if (application == null) {
                return;
            }
            if (application.stage == ApplicationInfo.MainStage || !sideStage.enabled) {
                mainStage.activateApplication(desktopFile, addDelay);
            } else {
                sideStage.activateApplication(desktopFile, addDelay);
            }
            stages.show();
        }
    }

    GSettings {
        id: backgroundSettings
        schema.id: "org.gnome.desktop.background"
    }
    property url gSettingsPicture: backgroundSettings.pictureUri != undefined && backgroundSettings.pictureUri.length > 0 ? backgroundSettings.pictureUri : shell.defaultBackground
    onGSettingsPictureChanged: {
        shell.background = gSettingsPicture
    }

    // This is a dummy image that is needed to determine if the picture url
    // in backgroundSettings points to a valid picture file.
    // We can't do this with the real background image because setting a
    // new source in onStatusChanged triggers a binding loop detection
    // inside Image, which causes it not to render even though a valid source
    // would be set. We don't mind about this image staying black and just
    // use it for verification to populate the source for the real
    // background image.
    Image {
        source: shell.background
        height: 0
        width: 0
        sourceSize.height: 0
        sourceSize.width: 0
        onStatusChanged: {
            if (status == Image.Error && source != shell.defaultBackground) {
                shell.background = defaultBackground
            }
        }
    }

    VolumeControl {
        id: volumeControl
    }

    Keys.onVolumeUpPressed: volumeControl.volumeUp()
    Keys.onVolumeDownPressed: volumeControl.volumeDown()

    Item {
        id: underlay
        objectName: "underlay"
        anchors.fill: parent

        // Whether the underlay is fully covered by opaque UI elements.
        property bool fullyCovered: false

        readonly property bool applicationRunning: ((mainStage.applications && mainStage.applications.count > 0)
                                           || (sideStage.applications && sideStage.applications.count > 0))

        // Whether the user should see the topmost application surface (if there's one at all).
        readonly property bool applicationSurfaceShouldBeSeen: applicationRunning && !stages.fullyHidden
                                           && !mainStage.usingScreenshots // but want sideStage animating over app surface



        // NB! Application surfaces are stacked behing the shell one. So they can only be seen by the user
        // through the translucent parts of the shell surface.
        visible: !fullyCovered && !applicationSurfaceShouldBeSeen

        CrossFadeImage {
            id: backgroundImage
            objectName: "backgroundImage"

            anchors.fill: parent
            source: shell.background
            fillMode: Image.PreserveAspectCrop
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: dash.disappearingAnimationProgress
        }

        Dash {
            id: dash
            objectName: "dash"

            available: !greeter.shown && !lockscreen.shown
            shown: disappearingAnimationProgress !== 1.0
            enabled: disappearingAnimationProgress === 0.0 && edgeDemo.dashEnabled
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
            property real disappearingAnimationProgress: {
                if (greeter.shown) {
                    return greeter.showProgress;
                } else {
                    return stagesOuterContainer.showProgress;
                }
            }

            // FIXME: only necessary because stagesOuterContainer.showProgress and
            // greeterRevealer.animatedProgress are not animated
            Behavior on disappearingAnimationProgress { SmoothedAnimation { velocity: 5 }}
        }
    }

    function showHome() {
        dash.setCurrentScope("home.scope", false, false)
    }

    Item {
        id: overlay

        anchors.fill: parent

        Panel {
            id: panel
            anchors.fill: parent //because this draws indicator menus
            indicatorsMenuWidth: parent.width > units.gu(60) ? units.gu(40) : parent.width
            fullscreenMode: shell.fullscreenMode
            searchVisible: !greeter.shown && !lockscreen.shown && dash.shown

            InputFilterArea {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                height: (panel.fullscreenMode) ? shell.edgeSize : panel.panelHeight
                blockInput: true
            }
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
    }

    focus: true
    onFocusChanged: if (!focus) forceActiveFocus();

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

    OSKController {
        anchors.topMargin: panel.panelHeight
        anchors.fill: parent // as needs to know the geometry of the shell
    }

    //FIXME: This should be handled in the input stack, keyboard shouldnt propagate
    MouseArea {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: shell.applicationManager ? shell.applicationManager.keyboardHeight : 0

        enabled: shell.applicationManager && shell.applicationManager.keyboardVisible
    }

    Connections {
        target: SessionBroadcast
        onShowHome: showHome()
    }
}
