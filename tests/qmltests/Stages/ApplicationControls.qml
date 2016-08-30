/*
 * Copyright (C) 2016 Canonical, Ltd.
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
    property var application

    RowLayout {
        Label {
            text: root.application.appId
            id: appIdLabel
        }
        MouseArea {
            width: height
            height: appIdLabel.height * 0.7
            anchors.verticalCenter: parent.verticalCenter
            onClicked: {
                if (root.application.instanceList.count > 0) {
                    root.application.createInstance();
                } else {
                    ApplicationManager.startApplication(root.application.appId);
                }
            }
            Label { text: "➕"; anchors.centerIn: parent }
        }
    }


    Repeater {
        model: root.application ? root.application.instanceList : null
        delegate: ApplicationInstanceControls {
            applicationInstance: model.applicationInstance
            instanceName: "instance " + (model.index + 1)
        }
    }
}
