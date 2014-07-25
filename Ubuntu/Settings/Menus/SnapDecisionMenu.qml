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
import Ubuntu.Components 1.1
import Ubuntu.Settings.Components 0.1 as USC
import QtQuick.Layouts 1.1

SimpleMessageMenu {
    id: menu

    property bool activateEnabled: true
    property string actionButtonText: "Call back"

    property bool replyEnabled: true
    property string replyButtonText: "Send"

    signal activated
    signal replied(string value)

    footer: Item {
        id: buttons

        implicitHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors {
                left: parent.left
                right: parent.right
            }
            spacing: units.gu(1)

            RowLayout {
                spacing: units.gu(2)

                Button {
                    objectName: "messageButton"
                    text: "Message"
                    gradient: UbuntuColors.greyGradient
                    Layout.fillWidth: true

                    onClicked: {
                        if (reply.state === "") {
                            reply.state = "expanded";
                        } else {
                            reply.state = "";
                        }
                    }
                }

                Button {
                    id: actionButton
                    objectName: "actionButton"
                    enabled: menu.activateEnabled
                    text: actionButtonText
                    Layout.fillWidth: true

                    onClicked: {
                        menu.activated();
                    }
                }
            }

            USC.ActionTextField {
                id: reply

                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: state == "expanded"

                activateEnabled: menu.replyEnabled
                buttonText: menu.replyButtonText

                onActivated: {
                    menu.replied(value);
                }
            }
        }
    }
}
