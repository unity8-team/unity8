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
import Ubuntu.Settings.Components 0.1 as USC
import QtQuick.Layouts 1.1

SimpleMessageMenu {
    id: menu

    property bool actionEnabled: true
    property string actionButtonText: i18n.dtr("ubuntu-settings-components", "Call back")

    property bool replyEnabled: true
    property string replyButtonText: i18n.dtr("ubuntu-settings-components", "Send")
    property string replyHintText
    property bool replyExpanded: false

    signal actionActivated
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
                    text: i18n.dtr("ubuntu-settings-components", "Message")
                    Layout.fillWidth: true

                    onClicked: {
                        menu.replyExpanded = !menu.replyExpanded;
                    }
                }

                Button {
                    id: actionButton
                    objectName: "actionButton"
                    enabled: menu.actionEnabled
                    text: actionButtonText
                    color: enabled ? theme.palette.normal.positive : theme.palette.inactive.positive
                    Layout.fillWidth: true

                    onClicked: {
                        menu.actionActivated();
                    }
                }
            }

            USC.ActionTextField {
                id: reply

                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: menu.replyExpanded

                activateEnabled: menu.replyEnabled
                buttonText: menu.replyButtonText
                textHint: menu.replyHintText

                onActivated: {
                    menu.replied(value);
                }
            }
        }
    }
}
