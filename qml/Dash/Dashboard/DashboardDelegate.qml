/*
 * Copyright (C) 2017 Canonical, Ltd.
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
import "../../Notifications"

Item {
    objectName: "dashboardDelegate" + index
    height: Math.max(units.gu(8), Math.floor(Math.random() * 300)) // FIXME base on actual data

    // read-write API
    property bool editMode: false

    // readonly API
    readonly property int visualIndex: index

    scale: editMode ? 0.95 : 1
    Behavior on scale { UbuntuNumberAnimation {} }

    Drag.keys: ["unity8-dashboard"]
    Drag.active: mouseArea.drag.active
    Drag.hotSpot.x: width/2
    Drag.hotSpot.y: height/2
    Drag.proposedAction: Qt.MoveAction
    Drag.onDragStarted: print("Drag started")
    Drag.onDragFinished: print("Drag finished")

    signal close()

    Rectangle {
        anchors.fill: parent
        radius: units.gu(.5)
        color: UbuntuColors.jet
        opacity: editMode ? 0.15 : 0.1
        Behavior on opacity { UbuntuNumberAnimation {} }
    }

    Label {
        id: label
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        text: model.name + " (" + index + ")" + (model.content ? "\n" + eval(model.content) : "")
        color: model.headerColor ? model.headerColor : "white"
    }

    MouseArea {
        id: mouseArea
        enabled: editMode
        anchors.fill: parent
        cursorShape: drag.active ? Qt.DragMoveCursor : undefined

        drag.target: parent
        onReleased: {
            if (drag.active) {
                var result = parent.Drag.drop();
                if (result) {
                    print("Drop accepted");
                } else {
                    print("Drop rejected");
                }
            }
        }
    }

    Timer {
        running: model.ttl
        repeat: running
        interval: running ? model.ttl : 0
        onTriggered: label.text = eval(model.content);
    }

    NotificationButton { // FIXME make this a generic component
        objectName: "closeButton"
        width: units.gu(3)
        height: width
        radius: width / 2
        visible: opacity > 0
        enabled: editMode
        opacity: enabled ? 1 : 0
        iconName: "close"
        outline: false
        hoverEnabled: true
        color: theme.palette.normal.negative
        anchors.horizontalCenter: parent.left
        anchors.horizontalCenterOffset: width/4
        anchors.verticalCenter: parent.top
        anchors.verticalCenterOffset: height/4

        onClicked: close();

        Behavior on opacity { UbuntuNumberAnimation {} }
    }
}
