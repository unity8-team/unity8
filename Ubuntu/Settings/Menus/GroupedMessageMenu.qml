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

ListItem.Empty {
    id: menu

    property alias title: __title.text
    property alias count: label.text
    property url appIcon

    signal appActivated()
    signal dismissed()

    implicitHeight: units.gu(10)

    Row {
        anchors.fill: parent
        anchors.margins: units.gu(2)
        spacing: units.gu(4)

        UbuntuShape {
            height: units.gu(6)
            width: units.gu(6)
            image: Image {
                objectName: "appIcon"
                source: appIcon != "" ? appIcon : "artwork/default_app.svg"
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    console.log("click");
                    menu.activateApp();
                }
            }
        }

        Label {
            id: __title
            objectName: "title"
            anchors.verticalCenter: parent.verticalCenter
            font.weight: Font.DemiBold
            fontSize: "medium"
        }

        Label {
            id: label
            objectName: "messageCount"

            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - x
            horizontalAlignment: Text.AlignRight
            font.weight: Font.DemiBold
            fontSize: "medium"
            text: "0"
        }
    }

    ListItem.ThinDivider {
        anchors.bottom: parent.bottom
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            menu.appActivated();
        }
    }

    onItemRemoved: {
        menu.dismissed();
    }
}
