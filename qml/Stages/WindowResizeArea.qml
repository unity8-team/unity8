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

import QtQuick 2.3
import Ubuntu.Components 1.1
import Utils 0.1

Item {
    id: root
    anchors.fill: target
    anchors.margins: -borderThickness

    signal pressed()

    property var windowStateStorage: WindowStateStorage

    // The target item managed by this. Must be a parent or a sibling
    // The area will anchor to it and manage move and resize events
    property Item target: null
    property string windowId: ""
    property int borderThickness: 0
    property int minWidth: 0
    property int minHeight: 0

    Component.onCompleted: {
        var windowState = windowStateStorage.getGeometry(root.windowId, Qt.rect(target.x, target.y, target.width, target.height))
        if (windowState !== undefined) {
            target.x = windowState.x
            target.y = windowState.y
            target.width = windowState.width
            target.height = windowState.height
        }
    }

    Component.onDestruction: {
        windowStateStorage.saveGeometry(root.windowId, Qt.rect(target.x, target.y, target.width, target.height))
    }

    ResizeArea {
        anchors.top: root.top
        anchors.bottom: root.bottom
        anchors.margins: root.borderThickness
        width: root.borderThickness

        leftBorder: true
        target: root.target
        onPressed: { root.pressed(); }
    }
    ResizeArea {
        anchors.right: root.right
        anchors.top: root.top
        anchors.topMargin: root.borderThickness
        anchors.bottom: root.bottom
        anchors.bottomMargin: root.borderThickness
        width: root.borderThickness

        rightBorder: true
        target: root.target
        onPressed: { root.pressed(); }
    }
    ResizeArea {
        anchors.left: root.left
        anchors.leftMargin: root.borderThickness
        anchors.right: root.right
        anchors.rightMargin: root.borderThickness
        anchors.top: root.top
        height: root.borderThickness

        topBorder: true
        target: root.target
        onPressed: { root.pressed(); }
    }
    ResizeArea {
        anchors.left: root.left
        anchors.leftMargin: root.borderThickness
        anchors.right: root.right
        anchors.rightMargin: root.borderThickness
        anchors.bottom: root.bottom
        height: root.borderThickness

        bottomBorder: true
        target: root.target
        onPressed: { root.pressed(); }
    }
    ResizeArea {
        anchors.left: root.left
        anchors.top: root.top
        width: root.borderThickness
        height: root.borderThickness

        topBorder: true
        leftBorder: true
        target: root.target
        onPressed: { root.pressed(); }
    }
    ResizeArea {
        anchors.left: root.left
        anchors.bottom: root.bottom
        width: root.borderThickness
        height: root.borderThickness

        bottomBorder: true
        leftBorder: true
        target: root.target
        onPressed: { root.pressed(); }
    }
    ResizeArea {
        anchors.right: root.right
        anchors.top: root.top
        width: root.borderThickness
        height: root.borderThickness

        topBorder: true
        rightBorder: true
        target: root.target
        onPressed: { root.pressed(); }
    }
    ResizeArea {
        anchors.right: root.right
        anchors.bottom: root.bottom
        width: root.borderThickness
        height: root.borderThickness

        bottomBorder: true
        rightBorder: true
        target: root.target
        onPressed: { root.pressed(); }
    }
}
