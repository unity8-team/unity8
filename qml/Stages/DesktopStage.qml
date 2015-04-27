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
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
 */

import QtQuick 2.3
import Ubuntu.Components 1.1
import Unity.Application 0.1
import "../Components/PanelState"
import Utils 0.1

FocusScope {
    id: root

    anchors.fill: parent

    property alias background: wallpaper.source

    property var windowStateStorage: WindowStateStorage
    CrossFadeImage {
        id: wallpaper
        anchors.fill: parent
        sourceSize { height: root.height; width: root.width }
        fillMode: Image.PreserveAspectCrop
    }

    Connections {
        target: ApplicationManager
        onApplicationAdded: {
            ApplicationManager.requestFocusApplication(ApplicationManager.get(ApplicationManager.count-1).appId)
        }

        onFocusRequested: {
            var appIndex = priv.indexOf(appId);
            var appDelegate = appRepeater.itemAt(appIndex);
            var fullscreen = (appDelegate.x ==0 && appDelegate.y ==0 && appDelegate.width ==root.width && appDelegate.height ==root.height)
            if (appDelegate.state === "minimized") {
                if (!appDelegate.maxtomin) {
                    appDelegate.getNorGeometry()
                    appDelegate.state = "normal"
                    appDelegate.maxtomin = false
                } else {
                    appDelegate.state = "maximized"
                    appDelegate.maxtomin = false
                }
            }
            if (appDelegate.state === "" ) {
                if (fullscreen) {
                    appDelegate.state = "maximized"
                }
                else {
                    if (appDelegate.getNorGeometry()) {
                        appDelegate.state = "normal"
                    }
                    else {
                        appDelegate.saveNorGeometry()
                        appDelegate.state = "normal"
                        }
                    }
            }
            ApplicationManager.focusApplication(appId);
        }
    }

    QtObject {
        id: priv

        readonly property string focusedAppId: ApplicationManager.focusedApplicationId
        readonly property var focusedAppDelegate: focusedAppId ? appRepeater.itemAt(indexOf(focusedAppId)) : null

        function indexOf(appId) {
            for (var i = 0; i < ApplicationManager.count; i++) {
                if (ApplicationManager.get(i).appId == appId) {
                    return i;
                }
            }
            return -1;
        }
    }

    Connections {
        target: PanelState
        onClose:  ApplicationManager.stopApplication(ApplicationManager.focusedApplicationId)
        onMinimize: {
            if (appRepeater.itemAt(0).state == "maximized") {
                appRepeater.itemAt(0).maxtomin = true
            }
            appRepeater.itemAt(0).state = "minimized"
        }
        onMaximize: {
            appRepeater.itemAt(0).getNorGeometry()
            appRepeater.itemAt(0).state = "normal"
        }
    }

    Binding {
        target: PanelState
        property: "buttonsVisible"
        value: priv.focusedAppDelegate !== null && priv.focusedAppDelegate.state === "maximized"
    }

    Repeater {
        id: appRepeater
        model: ApplicationManager

        delegate: Item {
            id: appDelegate
            z: ApplicationManager.count - index
            y: units.gu(3)
            width: units.gu(60)
            height: units.gu(50)
            readonly property int minWidth: units.gu(10)
            readonly property int minHeight: units.gu(10)
            property var windowstate
            property bool maxtomin: false
            function saveNorGeometry() {
                windowstate = Qt.rect(x,y,width,height)
                windowStateStorage.saveGeometry(model.appId, windowstate,1)
            }
            function getNorGeometry() {
                windowstate = windowStateStorage.getGeometry(model.appId, Qt.rect(null,null,null,null),1)
                    if(windowstate.width==0 ||windowstate.height==0){
                        return false
                    }
                        return true
            }
            function normalStateSave() {
                if (state == "normal") {
                    saveNorGeometry()
                }
            }
            states: [
                State {
                    name: "normal"
                    PropertyChanges { target: appDelegate; x:windowstate.x ; y:windowstate.y; width:windowstate.width; height:windowstate.height }
                },
                State {
                    name: "maximized"
                    PropertyChanges { target: appDelegate; x: 0; y: 0; width: root.width; height: root.height }
                },
                State {
                    name: "minimized"
                    PropertyChanges { target: appDelegate; x: -appDelegate.width / 2; scale: units.gu(5) / appDelegate.width; opacity: 0 }
                }
            ]
            transitions: [
                Transition {
                    PropertyAnimation { target: appDelegate; properties: "x,y,opacity,width,height,scale" }
                }
            ]

            WindowMoveResizeArea {
                windowStateStorage: root.windowStateStorage
                target: appDelegate
                minWidth: appDelegate.minWidth
                minHeight: appDelegate.minHeight
                resizeHandleWidth: units.gu(0.5)
                windowId: model.appId // FIXME: Change this to point to windowId once we have such a thing
                onPressed: decoratedWindow.focus = true;
            }

            DecoratedWindow {
                id: decoratedWindow
                objectName: "decoratedWindow_" + appId
                anchors.fill: parent
                application: ApplicationManager.get(index)
                active: ApplicationManager.focusedApplicationId === model.appId

                onFocusChanged: {
                    if (focus) {
                        ApplicationManager.requestFocusApplication(model.appId);
                    }
                }

                onClose: {
                    appDelegate.normalStateSave()
                    ApplicationManager.stopApplication(model.appId)
                }
                onMaximize: {
                    appDelegate.normalStateSave()
                    if(appDelegate.state == "maximized"){
                        appDelegate.getNorGeometry()
                    }
                    appDelegate.state = (appDelegate.state == "maximized" ? "normal" : "maximized")
                }
                onMinimize: {
                    appDelegate.normalStateSave()
                    if(appDelegate.state == "maximized"){
                        appDelegate.maxtomin = true
                    }
                    appDelegate.state = "minimized"
                }
            }
        }
    }
}
