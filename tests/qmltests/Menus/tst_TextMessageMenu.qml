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
 * Authored by Nick Dedekind <nick.dedekind@canonical.com>
 */

import QtQuick 2.0
import QtTest 1.0
import Ubuntu.Test 0.1
import Ubuntu.Settings.Menus 0.1

Item {
    width: units.gu(42)
    height: units.gu(75)

    Flickable {
        id: flickable

        anchors.fill: parent
        contentWidth: column.width
        contentHeight: column.height

        Item {
            id: column

            width: flickable.width
            height: childrenRect.height

            TextMessageMenu {
                id: messageMenu
                removable: false

                title: "Text Message"
                time: "11:08am"
                message: "I am a little teapot"
            }

            TextMessageMenu {
                id: messageMenuRemovable
                removable: true
                anchors.top: messageMenu.bottom
            }

            TextMessageMenu {
                id: messageMenuSelected
                removable: true
                anchors.top: messageMenuRemovable.bottom

                onReplied: {
                    textMessageReply = value;
                }
            }
        }
    }

    property string textMessageReply: ""

    SignalSpy {
        id: signalSpyActivateApp
        signalName: "appActivated"
        target: messageMenuSelected
    }

    SignalSpy {
        id: signalSpyDismiss
        signalName: "dismissed"
        target: messageMenuRemovable
    }

    SignalSpy {
        id: signalSpyReply
        signalName: "replied"
        target: messageMenuSelected
    }

    UbuntuTestCase {
        name: "TextMessageMenu"
        when: windowShown

        function init() {
            signalSpyActivateApp.clear();
            signalSpyDismiss.clear();
            signalSpyReply.clear();
            textMessageReply = "";

            messageMenu.replyEnabled = true;
            messageMenuSelected.selected = false;
        }

        function test_title_data() {
            return [
                { title: "title1" },
                { title: "title2" },
            ];
        }

        function test_title(data) {
            messageMenu.title = data.title;

            var title = findChild(messageMenu, "title");
            verify(title, "No title");
            compare(title.text, data.title, "Title does not match set title.");
        }

        function test_time_data() {
            return [
                { time: "11:09am" },
                { time: "4pm" },
            ];
        }

        function test_time(data) {
            messageMenu.time = data.time;

            var subtitle = findChild(messageMenu, "subtitle");
            verify(subtitle !== undefined, "No subtitle");
            compare(subtitle.text, data.time, "Time does not match set time.");
        }

        function test_appIcon_data() {
            return [
                { appIcon: Qt.resolvedUrl("../../artwork/avatar.png") },
                { appIcon: Qt.resolvedUrl("../../artwork/rhythmbox.png") },
            ];
        }

        function test_appIcon(data) {
            messageMenu.appIcon = data.appIcon;

            var appIcon = findChild(messageMenu, "appIcon");
            verify(appIcon !== undefined, "No app icon");
            compare(appIcon.source, data.appIcon, "App Icon does not match set icon.");
        }

        function test_message_data() {
            return [
                { message: "This is a test." },
                { message: "Test is also a test." },
            ];
        }

        function test_message(data) {
            messageMenu.message = data.message;

            var body = findChild(messageMenu, "body");
            verify(body !== undefined, "No body");
            compare(body.text, data.message, "Message does not match set message.");
        }

        function test_replyButtonText_data() {
            return [
                { buttonText: "Send" },
                { buttonText: "reply" },
            ];
        }

        function test_replyButtonText(data) {
            messageMenu.replyButtonText = data.buttonText;

            var button = findChild(messageMenu, "sendButton");
            verify(button !== undefined, "No send button");
            compare(button.text, data.buttonText, "Button text does not match set text.");
        }

        function test_activateApp() {
            var appIcon = findChild(messageMenuSelected, "appIcon");

            mouseClick(appIcon, appIcon.width * 2, appIcon.height / 2, Qt.LeftButton, Qt.NoModifier, 0);
            compare(signalSpyActivateApp.count, 0, "activate app should not have been triggered");

            messageMenuSelected.selected = false;
            mouseClick(appIcon, appIcon.width / 2, appIcon.height / 2, Qt.LeftButton, Qt.NoModifier, 0);
            compare(signalSpyActivateApp.count, 0, "activate app should not have been triggered when not selected");

            messageMenuSelected.selected = true;
            mouseClick(appIcon, appIcon.width / 2, appIcon.height / 2, Qt.LeftButton, Qt.NoModifier, 0);
            compare(signalSpyActivateApp.count > 0, true, "activate app should have been triggered when selected");
        }

        function test_dismiss() {
            mouseFlick(messageMenuRemovable,
                       messageMenuRemovable.width / 2,
                       messageMenuRemovable.height / 2,
                       messageMenuRemovable.width,
                       messageMenuRemovable.height / 2,
                       true, true, units.gu(1), 10);
            tryCompareFunction(function() { return signalSpyDismiss.count > 0; }, true);
        }

        function test_replyEnabled_data() {
            return [
                { tag: 'disabledNoReply', enabled: false, reply: "", expected: false},
                { tag: 'enabledNoReply', enabled: true, reply: "", expected: false},
                { tag: 'disabledWithReply', enabled: false, reply: "test", expected: false},
                { tag: 'enabledWithReply', enabled: true, reply: "test", expected: true},
            ];
        }

        function test_replyEnabled(data) {
            messageMenuSelected.selected = true;
            messageMenuSelected.replyEnabled = data.enabled

            var replyText = findChild(messageMenuSelected, "replyText");
            verify(replyText !== undefined, "Reply text not found");

            var sendButton = findChild(messageMenuSelected, "sendButton");
            verify(sendButton !== undefined, "Send button not found");

            replyText.text = data.reply;

            compare(sendButton.enabled, data.expected, "Reply button is not in correct state");
        }

        function test_reply() {
            messageMenuSelected.selected = true;
            messageMenuSelected.replyEnabled = true;

            var replyText = findChild(messageMenuSelected, "replyText");
            verify(replyText !== undefined, "Reply text not found");
            replyText.text = "reply1";

            var sendButton = findChild(messageMenuSelected, "sendButton");
            verify(sendButton !== undefined, "Send button not found");

            mouseClick(sendButton, sendButton.width / 2, sendButton.height / 2, Qt.LeftButton, Qt.NoModifier, 0);
            compare(signalSpyReply.count > 0, true);
            compare(textMessageReply, "reply1", "Text message did not reply with correct text.");
        }
    }
}
