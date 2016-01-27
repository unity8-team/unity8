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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
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
    property real _animationDuration: UbuntuAnimation.FastDuration

    __height: layout.implicitHeight + units.gu(3)
    clip: heightAnimation.running

    ColumnLayout {
        id: layout

        anchors {
            left: parent.left
            right: parent.right
            leftMargin: units.gu(2)
            rightMargin: units.gu(2)
            top: parent.top
            topMargin: units.gu(1.5)
        }
        spacing: units.gu(1.5)

        USC.MessageHeader {
            id: messageHeader
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop

            avatar: menu.avatar != "" ? menu.avatar : "image://theme/contact"
            icon: menu.icon != "" ? menu.icon : "image://theme/message"

            state: menu.state

            onIconClicked:  {
                menu.iconActivated();
            }
        }

        Loader {
            id: footerLoader
            visible: menu.state === "expanded"
            opacity: 0.0
            asynchronous: false
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    Behavior on height {
        NumberAnimation {
            id: heightAnimation
            duration: _animationDuration
            easing.type: Easing.OutQuad
        }
    }

    onTriggered: if (!footer || !selected) messageHeader.shakeIcon();

    states: State {
        name: "expanded"
        when: selected && footerLoader.status == Loader.Ready

        PropertyChanges {
            target: footerLoader
            opacity: 1.0
        }
    }

    transitions: Transition {
        ParallelAnimation {
            PropertyAnimation { target: footerLoader; property: "opacity"; duration:  _animationDuration }
        }
    }

    onItemRemoved: {
        menu.dismissed();
    }
}
