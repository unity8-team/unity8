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

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Settings.Components 0.1 as USC

ListItem.Empty {
    id: menu

    property alias heroMessageHeader: __heroMessageHeader
    property real collapsedHeight: heroMessageHeader.y + heroMessageHeader.bodyBottom + units.gu(2)
    property real expandedHeight: collapsedHeight

    property url avatar
    property url appIcon

    signal appActivated
    signal dismissed

    signal selected
    signal deselected

    removable: state !== "expanded"
    implicitHeight: collapsedHeight

    Rectangle {
        id: background
        property real alpha: 0.0

        anchors.fill: parent
        color: Qt.rgba(1.0, 1.0, 1.0, alpha)
        z: -1
    }

    USC.HeroMessageHeader {
        id: __heroMessageHeader

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        avatar: menu.avatar != "" ? menu.avatar : "artwork/default_contact.png"
        appIcon: menu.appIcon != "" ? menu.appIcon : "artwork/default_app.svg"
        icon: appIcon

        state: menu.state

        onAppIconClicked:  {
            deselectMenu();
            menu.appActivated();
        }
    }

    onClicked: {
        if (selected) {
            deselected();
        } else {
            selected();
        }
    }

    states: State {
        name: "expanded"
        when: selected

        PropertyChanges {
            target: menu
            implicitHeight: menu.expandedHeight
        }
        PropertyChanges {
            target: background
            alpha: 0.05
        }
    }

    transitions: Transition {
        ParallelAnimation {
            NumberAnimation {
                properties: "opacity,implicitHeight"
                duration: 200
                easing.type: Easing.OutQuad
            }
            ColorAnimation {}
        }
    }

    onItemRemoved: {
        menu.dismissed();
    }
}
