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
    readonly property bool painting: true
    property bool fullscreen: true
    property bool overlayMode: false

    readonly property int overlayWidth: priv.overlayOverride ? 0 : priv.sideStageWidth

    QtObject {
        id: priv

        property string focusedAppId: ApplicationManager.focusedApplicationId
        property string oldFocusedAppId: ""

        property string mainStageAppId
        property string sideStageAppId

        // For convenience, keep properties of the first two apps in the model
        property string appId0
        property string appId1

        onFocusedAppIdChanged: {
            print("focused appid changed", priv.focusedAppId)
            var focusedApp = ApplicationManager.findApplication(focusedAppId);
            if (focusedApp.stage == ApplicationInfoInterface.SideStage) {
                priv.sideStageAppId = focusedAppId;
            } else {
                priv.mainStageAppId = focusedAppId;
            }

            appId0 = ApplicationManager.get(0).appId;
            appId1 = ApplicationManager.get(1).appId;
        }
    }

    Connections {
        target: ApplicationManager
        onFocusRequested: {
            ApplicationManager.focusApplication(appId)
        }
    }

    Flickable {
        id: spreadView
        anchors.fill: parent
        contentWidth: spreadRow.width

        property int tileDistance: units.gu(10)
        property int sideStageWidth: units.gu(40)
        property bool sideStageVisible: priv.sideStageAppId

        property int phase

        property int phase0Width: sideStageWidth
        property int phase1Width: sideStageWidth

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
        onNextInStackChanged: print("next in stack is", nextInStack)

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

        Rectangle {
            id: spreadRow
            x: spreadView.contentX
            height: root.height
//            width: root.width
            width: Math.max(6, ApplicationManager.count) * spreadView.tileDistance + (spreadView.width - spreadView.tileDistance) * 1.5

            color: "black"

            Repeater {
                model: ApplicationManager

                delegate: Rectangle {
                    height: spreadView.height
                    width: spreadView.tileDistance
                    color: "#44FF0000"
                    x: spreadView.width             //  - units.gu(10) // just to see 'em

                    // We need to shuffle z ordering a bit in order to keep side stage apps above main stage apps.
                    // We don't want to really reorder them in the model because that allows us to keep track
                    // of the last focused order.
                    z: {
                        if (spreadTile.active && model.stage == ApplicationInfoInterface.MainStage) return 0;
                        if (spreadTile.active && model.stage == ApplicationInfoInterface.SideStage) {
                            if (ApplicationManager.get(spreadView.nextInStack).stage == ApplicationInfoInterface.MainStage) {
                                return Math.max(index, 2);
                            } else {
                                return 1;
                            }
                        }
                        if (index <= 2 && model.stage == ApplicationInfoInterface.MainStage && priv.sideStageAppId) return 1;
                        if (index == spreadView.nextInStack && model.stage == ApplicationInfoInterface.SideStage) return 2;
                        return index;
                    }

                    TransformedTabletSpreadDelegate {
                        id: spreadTile
                        height: spreadView.height
                        width: model.stage == ApplicationInfoInterface.MainStage ? spreadView.width : spreadView.sideStageWidth
                        opacity: .3

                        active: model.appId == priv.mainStageAppId || model.appId == priv.sideStageAppId
                        zIndex: parent.z

                        progress: {
                            var prog = 0;
                            switch (spreadView.phase) {
                            case 0:
                                // Calculate a progress of 0..1 while moving within phase0Width.
                                prog = spreadView.contentX / spreadView.phase0Width;
                                break;
                            case 1:
                                prog = (spreadView.contentX - spreadView.phase0Width) / spreadView.phase1Width;
                                break;
                            case 2:
                                prog = (spreadView.contentX - zIndex * spreadView.tileDistance) / spreadView.width;
                            }
                            print("*** INDEX:", zIndex, " PHASE:", spreadView.phase, " PROGRESS:", prog, "contentX", spreadView.contentX);
                            return prog;
                        }


                        EasingCurve {
                            id: snappingCurve
                            type: EasingCurve.OutQuad
                            period: 0.05
                            progress: spreadTile.progress
                        }

                        Rectangle {
                            anchors.fill: parent; color: "#FF00FF"
                            border.width: units.gu(1)
                            border.color: "black"
                            Label {
                                anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: units.gu(2) }
                                fontSize: "x-large"
                                text: spreadTile.zIndex + "/" + model.index
                            }
                        }
                    }
                }
            }
        }
    }

    EdgeDragArea {
        id: spreadDragArea
        anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
        width: root.dragAreaWidth

        Rectangle { anchors.fill: parent; color: "#4400FF00"}

        onTouchXChanged: {
            print("touchX changed. dragging", dragging)
            if (!dragging) {
                spreadView.phase = 0;
                spreadView.contentX = 0;
            } else {
                spreadView.contentX = -touchX + spreadDragArea.width
            }

            if (spreadView.phase == 0 && spreadView.contentX > spreadView.phase0Width) {
                spreadView.phase = 1;
            } else if (spreadView.phase == 1 && spreadView.contentX - spreadView.phase0Width > spreadView.phase1Width) {
                spreadView.phase = 2;
            } else if (spreadView.phase == 1 && spreadView.contentX < spreadView.phase0Width) {
                spreadView.phase = 0;
            }

        }
    }
}
