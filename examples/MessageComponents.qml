/*
 * Copyright 2014 Canonical Ltd.
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
 * Authored by Andrea Cimitan <andrea.cimitan@canonical.com>
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Settings.Components 0.1
import Ubuntu.Settings.Menus 0.1

Item {
    property string title: "MessageComponents"

    width: units.gu(42)
    height: units.gu(75)

    ListModel {
        id: model
        ListElement {
            type: "text"
            title: "Text Message"
            body: "I am a little teacup, short and stout. Here is my handle, and here is my spout. Who are you talking about my spout?! This should be truncated"
            time: "Sat 31 Oct, 11:00"
            icon: "image://theme/message"
            avatar: "image://theme/contact"
        }
        ListElement {
            type: "simple"
            title: "Simple Text Message Simple"
            body: "I happen to be tall and thin! But let's try a new line"
            time: "Yesterday, 10:00"
            icon: "image://theme/message"
            avatar: "artwork/beach.jpg"
        }
        ListElement {
            type: "snap"
            title: "Snap Decision"
            body: "My mother says I'm handsome!"
            time: "10:30am"
            icon: "image://theme/missed-call"
            avatar: "artwork/night.jpg"
        }
    }

    ListView {
        model: model
        anchors.fill: parent

        cacheBuffer: 10000

        delegate: Loader {
            anchors {
                left: parent.left
                right: parent.right
            }
            asynchronous: true
            sourceComponent: model.type === "simple" ? simple :
                             model.type === "text" ? text :
                             model.type === "snap" ? snap : undefined

            Component {
                id: simple
                SimpleMessageMenu {
                    avatar: model.avatar
                    icon: model.icon
                    title: model.title
                    body: model.body
                    time: model.time
                    removable: true
                }
            }

            Component {
                id: text
                TextMessageMenu {
                    avatar: model.avatar
                    icon: model.icon
                    title: model.title
                    body: model.body
                    time: model.time
                    removable: true
                    replyHintText: "Reply"

                    onTriggered: {
                        selected = !selected;
                    }
                }
            }

            Component {
                id: snap
                SnapDecisionMenu {
                    avatar: model.avatar
                    icon: model.icon
                    title: model.title
                    body: model.body
                    time: model.time
                    removable: true
                    replyHintText: "Reply"

                    onTriggered: {
                        selected = !selected;
                    }
                }
            }
        }
    }
}
