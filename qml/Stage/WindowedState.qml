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
import Utils 0.1

Item { // needs to be an item for VirtualPosition to work.
    id: root
    property Item target: null

    property int defaultX: units.gu(10)
    property int defaultY: units.gu(10)
    property int defaultWidth: units.gu(60)
    property int defaultHeight: units.gu(60)

    readonly property alias valid: sharedState.valid
    property alias windowId: sharedState.windowId
    property alias state: sharedState.state
    property alias stateSource: sharedState.stateSource
    property alias stage: sharedState.stage
    property alias spread: sharedState.spread
    property alias scale: sharedState.scale
    property alias opacity2: sharedState.opacity
    readonly property alias geometry: sharedState.geometry
    readonly property alias windowedGeometry: sharedState.windowedGeometry

    property alias relativePosition: relativeMappedPosition
    property alias absolutePosition: absoluteMappedPosition

    SharedWindowState {
        id: sharedState

        // only first shared instance should load state
        property bool shouldLoadState: false
        onInitialized: {
            shouldLoadState = true;
        }
    }

    Component.onCompleted: {
        if (sharedState.shouldLoadState) {
            loadWindowedState();
        }
    }

    VirtualPosition {
        id: relativeMappedPosition
        objectName: "relativePosition"
        direction: VirtualPosition.FromDesktop
        enableWindowChanges: false
    }

    // map from postion relative to window to the "virtual desktop" space.
    VirtualPosition {
        id: absoluteMappedPosition
        objectName: "absolutePosition"
        direction: VirtualPosition.ToDesktop
        enableWindowChanges: false
    }

    function loadWindowedState() {
        var mapped0 = absoluteMappedPosition.map(Qt.point(defaultX,defaultY));
        defaultX = -1; defaultX = -1;

        var geo = WindowStateStorage.getGeometry(model.application.appId,
                                       Qt.rect(mapped0.x,
                                               mapped0.y,
                                               defaultWidth,
                                               defaultHeight));
        console.log("loadWindowState", screenWindow.objectName, geo);

        var mapped = relativeMappedPosition.map(Qt.point(geo.x, geo.y));
        windowedGeometry.x = geo.x;
        windowedGeometry.y = geo.y;
        windowedGeometry.width = geo.width;
        windowedGeometry.height = geo.height;

        target.animationsEnabled = false;
        var windowState = WindowStateStorage.getState(windowId, WindowState.Normal);
        switch (windowState) {
            case WindowStateStorage.WindowStateNormal:
                state = WindowState.Normal;
                break;
            case WindowStateStorage.WindowStateMaximized:
                state = WindowState.Maximized;
                break;
            case WindowStateStorage.WindowStateMaximizedLeft:
                state = WindowState.MaximizedLeft;
                break;
            case WindowStateStorage.WindowStateMaximizedRight:
                state = WindowState.MaximizedRight;
                break;
            case WindowStateStorage.WindowStateMaximizedHorizontally:
                state = WindowState.MaximizedHorizontally;
                break;
            case WindowStateStorage.WindowStateMaximizedVertically:
                state = WindowState.MaximizedVertically;
                break;
            default:
                console.warn("Unsupported window state");
                break;
        }
    }

    function saveWindowedState() {
        var geo = Qt.rect(windowedGeometry.x,
                          windowedGeometry.y,
                          windowedGeometry.width,
                          windowedGeometry.height);
        console.log("saveWindowState", screenWindow.objectName, geo, state);

        WindowStateStorage.saveGeometry(windowId, geo);
        WindowStateStorage.saveState(windowId, state);
    }
}
