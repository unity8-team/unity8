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

Item {
    id: quickReply
    property alias buttonText: actionTextField.buttonText
    property real expandedHeight: childrenRect.height
    property alias messages : messagelistRepeater.model
    property alias replyEnabled: actionTextField.activateEnabled
    property real messageMargins: units.gu(2)

    signal replied(var value)

    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: units.gu(4)

        Row {
            anchors {
                fill: parent
                topMargin: units.gu(1)
                bottomMargin: units.gu(1)
                leftMargin: messageMargins
                rightMargin: messageMargins
            }
            spacing: units.gu(1)

            Image {
                width: units.gu(2)
                height: width
                fillMode: Image.PreserveAspectFit
                source: "image://theme/message"
            }

            Label {
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                fontSize: "small"
                text: i18n.dtr("ubuntu-settings-components", "Quick reply with:")
            }
        }

        ListItem.ThinDivider {
            anchors.bottom: parent.bottom
        }
    }

    Column {
        id: messagelist
        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
        }
        height: childrenRect.height

        Repeater {
            id: messagelistRepeater

            height: childrenRect.height

            Item {
                objectName: "replyMessage" + index
                width: messagelist.width
                height: units.gu(5)

                Label {
                    id: __label

                    anchors {
                        fill: parent
                        leftMargin: messageMargins
                        rightMargin: messageMargins
                    }
                    verticalAlignment: Text.AlignVCenter
                    fontSize: "medium"
                    text: modelData
                }

                ListItem.ThinDivider {
                    anchors.top: parent.top
                }
                ListItem.ThinDivider {
                    anchors.bottom: parent.bottom
                }

                MouseArea {
                    id: __mouseArea

                    anchors.fill: parent
                    onClicked: {
                        actionTextField.text = modelData;
                    }
                }

                Rectangle {
                    id: __mask

                    anchors.fill: parent
                    color: "black"
                    opacity: __mouseArea.pressed ? 0.3 : 0.0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }

        }
    }

    Item {
        anchors.top: messagelist.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: units.gu(6)

        ActionTextField {
            id: actionTextField

            anchors.fill: parent
            anchors {
                topMargin: units.gu(1)
                bottomMargin: units.gu(1)
                leftMargin: messageMargins
                rightMargin: messageMargins
            }
            activateEnabled: replyEnabled

            onActivated: {
                quickReply.replied(value)
            }
        }

        ListItem.ThinDivider {
            anchors.top: parent.top
        }
    }
}
