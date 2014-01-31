/*
 * Copyright: 2013 Canonical, Ltd
 *
 * This file is part of reminders-app
 *
 * reminders-app is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1
import Ubuntu.OnlineAccounts 0.1
import Ubuntu.OnlineAccounts.Client 0.1
import Evernote 0.1

Page {
    id: root
    title: "Select Evernote account"

    AccountServiceModel {
        id: accounts
        // Use the Evernote service
        service: "evernote"
    }

    Setup {
        id: setup
        applicationId: "com.ubuntu.reminders_reminders"
        providerId: "evernote"
    }

    Column {
        anchors { fill: parent; margins: units.gu(2) }
        spacing: units.gu(1)

        ListView {
            width: parent.width
            height: units.gu(10)
            model: accounts
            delegate: Standard {
                text: displayName

                // FIXME: remove this Item wrapper once Ubuntu ListItems are fixed to hold non-visual items
                Item {
                    AccountService {
                        id: accountService
                        objectHandle: accountServiceHandle
                        // Print the access token on the console
                        onAuthenticated: {
                            console.log("Access token is " + reply.AccessToken)
                            EvernoteConnection.token = reply.AccessToken;
                            pagestack.pop();
                        }
                        onAuthenticationError: { console.log("Authentication failed, code " + error.code) }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: accountService.authenticate(null)
                }
            }

            footer: Button {
                text: "Add account"
                onClicked: setup.exec()
            }
        }

    }
}
