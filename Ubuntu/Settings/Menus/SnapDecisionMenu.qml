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
import Ubuntu.Settings.Components 0.1 as USC

HeroMessageMenu {
    id: menu

    property string title: ""
    property string time: ""
    property string message: ""

    property bool activateEnabled: true
    property alias actionButtonText: actionButton.text

    property bool replyEnabled: true
    property alias replyMessages: quickreply.messages
    property alias replyButtonText: quickreply.buttonText

    expandedHeight: collapsedHeight + buttons.height + quickreply.height
    heroMessageHeader.titleText.text:  title
    heroMessageHeader.subtitleText.text: message
    heroMessageHeader.bodyText.text: time

    signal activated
    signal replied(string value)

    Item {
        id: buttons

        anchors.left: parent.left
        anchors.leftMargin: units.gu(2)
        anchors.right: parent.right
        anchors.rightMargin: units.gu(2)
        anchors.top: heroMessageHeader.bottom
        anchors.topMargin: units.gu(1)
        height: units.gu(4)
        opacity: 0.0

        Button {
            objectName: "messageButton"
            text: "Message"
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: (parent.width - units.gu(1)) / 2
            gradient: UbuntuColors.greyGradient

            onClicked: {
                if (quickreply.state === "") {
                    quickreply.state = "expanded";
                } else {
                    quickreply.state = "";
                }
            }
        }

        Button {
            id: actionButton
            objectName: "actionButton"
            text: "Call back"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: (parent.width - units.gu(1)) / 2
            enabled: menu.activateEnabled

            onClicked: {
                menu.activated();
            }
        }

        states: State {
            name: "expanded"
            when: menu.state === "expanded"

            PropertyChanges {
                target: buttons
                opacity: 1.0
            }
        }
        transitions: Transition {
            NumberAnimation {
                property: "opacity"
                duration: 200
                easing.type: Easing.OutQuad
            }
        }
    }

    USC.QuickReply {
        id: quickreply

        onReplied: {
            menu.replied(value);
        }

        messages: ""
        buttonText: "Send"
        anchors {
            top: buttons.bottom
            topMargin: units.gu(2)
            left: parent.left
            right: parent.right
        }
        height: 0
        opacity: 0.0
        enabled: false
        replyEnabled: menu.replyEnabled
        messageMargins: __contentsMargins

        states: State {
            name: "expanded"

            PropertyChanges {
                target: quickreply
                height: expandedHeight + units.gu(2)
                opacity: 1.0
            }

            PropertyChanges {
                target: quickreply
                enabled: true
            }
        }

        transitions: Transition {
            NumberAnimation {
                properties: "opacity,height"
                duration: 200
                easing.type: Easing.OutQuad
            }
        }
    }

    onStateChanged: {
        if (state === "") {
            quickreply.state = "";
        }
    }
}
