/*
 * Copyright 2013 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 *      Renato Araujo Oliveira Filho <renato@canonical.com>
 *      Olivier Tilloy <olivier.tilloy@canonical.com>
 */

import QtQuick 2.1
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Settings.Components 0.1 as USC
import QtQuick.Layouts 1.1

ListItem.Empty {
    id: menu

    property alias title: messageHeader.title
    property alias time: messageHeader.time
    property alias body: messageHeader.body

    property url avatar
    property url icon

    signal iconActivated
    signal dismissed

    property alias footer: footerLoader.sourceComponent

    implicitHeight: layout.height + units.gu(3)

    Rectangle {
        id: background
        property real alpha: 0.0

        anchors.fill: parent
        color: Qt.rgba(1.0, 1.0, 1.0, alpha)
        z: -1
    }

    ColumnLayout {
        id: layout

        anchors {
            left: parent.left
            right: parent.right
            leftMargin: units.gu(2)
            rightMargin: units.gu(2)
            verticalCenter: parent.verticalCenter
        }
        spacing: units.gu(1.5)

        USC.MessageHeader {
            id: messageHeader
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop

            avatar: menu.avatar != "" ? menu.avatar : "artwork/default_contact.png"
            icon: menu.icon != "" ? menu.icon : "artwork/default_app.svg"

            state: menu.state

            onIconClicked:  {
                menu.iconActivated();
            }
        }

        Loader {
            id: footerLoader
            visible: menu.state === "expanded"
            asynchronous: false
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    onTriggered: if (!footer || !selected) messageHeader.shakeIcon();

    states: State {
        name: "expanded"
        when: selected && footerLoader.status == Loader.Ready

        PropertyChanges {
            target: background
            alpha: 0.05
        }
    }

    transitions: Transition {
        ParallelAnimation {
            NumberAnimation {
                properties: "height"
                duration: 200
                easing.type: Easing.OutQuad
            }
            ColorAnimation { target: background}
        }
    }

    onItemRemoved: {
        menu.dismissed();
    }
}
