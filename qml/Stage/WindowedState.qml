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

UnityObject {
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
    property alias opacity: sharedState.opacity
    property alias scale: sharedState.scale
    readonly property alias geometry: sharedState.geometry

    property alias relativePosition: relativeMappedPosition
    property alias absolutePosition: absoluteMappedPosition

    property list<QtObject> objects
    default property alias children: root.objects


    SharedWindowState {
        id: sharedState

        // only first shared instnace gets this.
        onInitialized: {
            loadWindowState();
        }

        geometry {
            x: absoluteMappedPosition.mappedX
            y: absoluteMappedPosition.mappedY
        }
    }

    VirtualPosition {
        id: relativeMappedPosition
        direction: VirtualPosition.FromDesktop
        enableWindowChanges: false
    }

    // map from postion relative to window to the "virtual desktop" space.
    VirtualPosition {
        id: absoluteMappedPosition
        direction: VirtualPosition.ToDesktop
        enableWindowChanges: false
    }

    function loadWindowState() {
        var mapped0 = absoluteMappedPosition.map(Qt.point(defaultX,defaultY));

        var geo = WindowStateStorage.getGeometry(model.application.appId,
                                       Qt.rect(mapped0.x,
                                               mapped0.x,
                                               defaultWidth,
                                               defaultHeight));
        console.log("loadWindowState", screenWindow.objectName, geo);

        var mapped = relativeMappedPosition.map(Qt.point(geo.x, geo.y));
        target.windowedX = mapped.x;
        target.windowedY = mapped.y;
        target.windowedWidth = geo.width;
        target.windowedHeight = geo.height;

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

    function saveWindowState() {
        var geo = Qt.rect(windowState.geometry.x,
                          windowState.geometry.y,
                          windowState.geometry.width,
                          windowState.geometry.height);
        console.log("saveWindowState", screenWindow.objectName, geo, state);

        WindowStateStorage.saveGeometry(windowId, geo);
        WindowStateStorage.saveState(windowId, state);
    }
}
