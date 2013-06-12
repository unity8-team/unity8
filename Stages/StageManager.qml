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
import "../Components"
import "../Components/Math.js" as MathLocal

Item {
    id: stageManager

    property var applicationManager
    property real leftSwipePosition: 0
    property real panelHeight: 0
    property real edgeHandleSize
    property bool enabled
    property var hides: []
    readonly property bool shown: stages.shown
    readonly property real animatedProgress: MathLocal.clamp((-stagesRevealer.dragPosition - leftSwipePosition)
                                                             / stagesRevealer.closedValue, 0, 1)

    readonly property bool stageScreenshotsReady: {
        if (sideStage.shown) {
            if (mainStage.applications.count > 0) {
                return mainStage.usingScreenshots || sideStage.usingScreenshots;
            } else {
                return sideStage.usingScreenshots;
            }
        } else {
            return mainStage.usingScreenshots;
        }
    }

    readonly property bool needUnderlay: (stages.fullyHidden
              || (stages.fullyShown && mainStage.usingScreenshots)
              || !stages.fullyShown && (mainStage.usingScreenshots || (sideStage.shown && sideStage.usingScreenshots)))

    readonly property bool fullscreenMode: {
        if (!enabled) {
            return false;
        } else if (mainStage.usingScreenshots) { // Window Manager animating so want to re-evaluate fullscreen mode
            return mainStage.switchingFromFullscreenToFullscreen;
        } else if (applicationManager.mainStageFocusedApplication) {
            return applicationManager.mainStageFocusedApplication.fullscreen;
        } else {
            return false;
        }
    }

    readonly property alias mainStageFullyShown: mainStage.fullyShown
    readonly property alias sideStageFullyShown: sideStage.fullyShown

    function hide() {
        stages.hide()
    }

    Component.onCompleted: {
        applicationManager.sideStageEnabled = Qt.binding(function() { return sideStage.enabled })

        // FIXME: if application focused before shell starts, shell draws on top of it only.
        // We should detect already running applications on shell start and bring them to the front.
        applicationManager.unfocusCurrentApplication();
    }

    Connections {
        target: applicationManager
        ignoreUnknownSignals: true
        onFocusRequested: {
            // TODO: this should be protected to only unlock for certain applications / certain usecases
            // potentially only in connection with a notification
            shell.greeter.hide();
            activateApplication(desktopFile);
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
    Item {
        id: windowsContainer

        x: leftSwipePosition
        Behavior on x {SmoothedAnimation{velocity: 600}}

        width: parent.width
        anchors {
            top: parent.top
            bottom: parent.bottom
        }

        Showable {
            id: stages

            property bool fullyShown: shown && stages[stagesRevealer.boundProperty] == stagesRevealer.openedValue
                                      && parent.x == 0
            property bool fullyHidden: !shown && stages[stagesRevealer.boundProperty] == stagesRevealer.closedValue
            available: stageManager.enabled
            hides: stageManager.hides
            shown: false
            opacity: 1.0
            showAnimation: StandardAnimation { property: "x"; duration: 350; to: stagesRevealer.openedValue; easing.type: Easing.OutCubic }
            hideAnimation: StandardAnimation { property: "x"; duration: 350; to: stagesRevealer.closedValue; easing.type: Easing.OutCubic }

            width: parent.width
            height: parent.height

            // close the stages when no focused application remains
            Connections {
                target: applicationManager
                onMainStageFocusedApplicationChanged: stages.closeIfNoApplications()
                onSideStageFocusedApplicationChanged: stages.closeIfNoApplications()
                ignoreUnknownSignals: true
            }
            Connections {
                target: applicationManager.mainStageApplications
                onCountChanged: stages.closeIfNoApplications();
            }
            Connections {
                target: applicationManager.sideStageApplications
                onCountChanged: stages.closeIfNoApplications();
            }

            function closeIfNoApplications() {
                if (!applicationManager.mainStageFocusedApplication
                 && !applicationManager.sideStageFocusedApplication
                 && applicationManager.mainStageApplications.count == 0
                 && applicationManager.sideStageApplications.count == 0) {
                    stages.hide();
                }
            }

            // show the stages when an application gets the focus
            Connections {
                target: applicationManager
                onMainStageFocusedApplicationChanged: {
                    if (applicationManager.mainStageFocusedApplication) {
                        mainStage.show();
                        stages.show();
                    }
                }
                onSideStageFocusedApplicationChanged: {
                    if (applicationManager.sideStageFocusedApplication) {
                        sideStage.show();
                        stages.show();
                    }                }
                ignoreUnknownSignals: true
            }

            Stage {
                id: mainStage
                objectName: "mainStage"

                anchors.fill: parent
                fullyShown: stages.fullyShown
                shouldUseScreenshots: !fullyShown
                rightEdgeEnabled: !sideStage.enabled

                applicationManager: stageManager.applicationManager
                rightEdgeDraggingAreaWidth: edgeHandleSize
                normalApplicationY: panelHeight

                shown: true
                function show() {
                    stages.show();
                }
                function showWithoutAnimation() {
                    stages.showWithoutAnimation();
                }
                function hide() {
                }

                // FIXME: workaround the fact that focusing a main stage application
                // raises its surface on top of all other surfaces including the ones
                // that belong to side stage applications.
                onFocusedApplicationChanged: {
                    if (focusedApplication && sideStage.focusedApplication && sideStage.fullyShown) {
                        applicationManager.focusApplication(sideStage.focusedApplication);
                    }
                }
            }

            SideStage {
                id: sideStage
                objectName: "sideStage"

                applicationManager: stageManager.applicationManager
                rightEdgeDraggingAreaWidth: edgeHandleSize
                normalApplicationY: panelHeight

                onShownChanged: {
                    if (!shown && mainStage.applications.count == 0) {
                        stages.hide();
                    }
                }
                // FIXME: when hiding the side stage, refocus the main stage
                // application so that it goes in front of the side stage
                // application and hides it
                onFullyShownChanged: {
                    if (!fullyShown && stages.fullyShown && sideStage.focusedApplication != null) {
                        applicationManager.focusApplication(mainStage.focusedApplication);
                    }
                }

                enabled: stageManager.width >= units.gu(60)
                visible: enabled
                fullyShown: stages.fullyShown && shown
                            && sideStage[sideStageRevealer.boundProperty] == sideStageRevealer.openedValue
                shouldUseScreenshots: !fullyShown || mainStage.usingScreenshots || sideStageRevealer.pressed

                available: stageManager.enabled && enabled
                hides: stageManager.hides
                shown: false
                showAnimation: StandardAnimation { property: "x"; duration: 350; to: sideStageRevealer.openedValue; easing.type: Easing.OutQuint }
                hideAnimation: StandardAnimation { property: "x"; duration: 350; to: sideStageRevealer.closedValue; easing.type: Easing.OutQuint }

                width: units.gu(40)
                height: stages.height
                handleExpanded: sideStageRevealer.pressed
            }

            Revealer {
                id: sideStageRevealer

                enabled: mainStage.applications.count > 0 && sideStage.applications.count > 0
                         && sideStage.available
                direction: Qt.RightToLeft
                openedValue: parent.width - sideStage.width
                hintDisplacement: units.gu(3)
                /* The size of the sidestage handle needs to be bigger than the
                   typical size used for edge detection otherwise it is really
                   hard to grab.
                */
                handleSize: sideStage.shown ? units.gu(4) : edgeHandleSize
                closedValue: parent.width + sideStage.handleSizeCollapsed
                target: sideStage
                x: parent.width - width
                width: sideStage.width + handleSize * 0.7
                height: sideStage.height
                orientation: Qt.Horizontal
            }
        }
    }

    Revealer {
        id: stagesRevealer

        enabled: mainStage.applications.count > 0 || sideStage.applications.count > 0
        direction: Qt.RightToLeft
        openedValue: 0
        hintDisplacement: units.gu(3)
        handleSize: edgeHandleSize
        closedValue: width
        target: stages
        width: stages.width
        height: stages.height
        orientation: Qt.Horizontal
    }
}
