/*
 * Copyright (C) 2015-2016 Canonical, Ltd.
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
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Unity.Application 0.1

Column {
    id: root
    property bool checked: false

    // set from outside
    property var applicationInstance
    property string instanceName

    function createSurface() {
        if (applicationInstance) {
            applicationInstance.createSurface();
        }
    }

    // Application checkbox row
    RowLayout {

        Layout.fillWidth: true
        Label {
            id: appIdLabel
            text: root.instanceName
            anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle {
            color: {
                if (root.applicationInstance) {
                    if (root.applicationInstance.state === ApplicationInstanceInterface.Starting) {
                        return "yellow";
                    } else if (root.applicationInstance.state === ApplicationInstanceInterface.Running) {
                        return "green";
                    } else if (root.applicationInstance.state === ApplicationInstanceInterface.Suspended) {
                        return "blue";
                    } else {
                        return "darkred";
                    }
                } else {
                    return "darkred";
                }
            }
            width: height
            height: appIdLabel.height * 0.7
            anchors.verticalCenter: parent.verticalCenter
        }

        MouseArea {
            width: height
            height: appIdLabel.height * 0.7
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.createSurface()
            enabled: root.applicationInstance && root.applicationInstance.state === ApplicationInstanceInterface.Running
            visible: enabled
            Label {
                text: "➕"
                anchors.centerIn: parent
            }
        }
    }

    // Prompts controls row
    RowLayout {
        anchors.left: root.left
        anchors.leftMargin: units.gu(2)
        visible: root.checked === true && root.applicationInstance !== null && root.enabled
        spacing: units.gu(1)
        Label {
            property int promptCount: root.applicationInstance ? root.applicationInstance.promptSurfaceList.count : 0
            id: promptsLabel
            text: promptCount + " prompts"
        }
        MouseArea {
            width: height
            height: promptsLabel.height * 0.7
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.applicationInstance.promptSurfaceList.createSurface()
            Label { text: "➕"; anchors.centerIn: parent }
        }
        MouseArea {
            width: height
            height: promptsLabel.height * 0.7
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.applicationInstance.promptSurfaceList.get(0).close()
            enabled: root.applicationInstance && root.applicationInstance.promptSurfaceList.count > 0
            Label { text: "➖"; anchors.centerIn: parent; enabled: parent.enabled }
        }
    }

    // Rows of application surfaces
    Repeater {
        model: root.applicationInstance ? root.applicationInstance.surfaceList : null
        RowLayout {
            anchors.left: root.left
            anchors.leftMargin: units.gu(2)
            spacing: units.gu(1)
            Label {
                text: "- " + model.surface.name
            }
            MouseArea {
                width: height
                height: appIdLabel.height * 0.7
                anchors.verticalCenter: parent.verticalCenter
                enabled: model.surface.live
                visible: enabled
                onClicked: model.surface.setLive(false);
                Label {
                    text: "⛒"
                    anchors.centerIn: parent
                }
            }
        }
    }
}
