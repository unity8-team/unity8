/*
 * Copyright: 2013 Canonical, Ltd
 *
 * This file is part of reminders
 *
 * reminders is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
//import "components"
import "ui"
import Evernote 0.1
import Ubuntu.OnlineAccounts 0.1

/*!
    \brief MainView with a Label and Button elements.
*/

MainView {
    id: root
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "com.ubuntu.reminders"

    /*
     This property enables the application to change orientation
     when the device is rotated. The default is false.
    */
    //automaticOrientation: true

    width: units.gu(50)
    height: units.gu(75)

    // Temporary background color. This can be changed to other suitable backgrounds when we get official mockup designs
    backgroundColor: UbuntuColors.coolGrey

    AccountServiceModel {
        id: accounts
        service: "evernote"
    }

    AccountService {
        id: accountService
        onObjectHandleChanged: authenticate(null);
        onAuthenticated: {
            console.log("Access token is " + reply.AccessToken)
            EvernoteConnection.token = reply.AccessToken;
        }
        onAuthenticationError: {
            console.log("Authentication failed, code " + error.code)
        }
    }

    Component.onCompleted: {
        pagestack.push(rootTabs)
        print("got accounts:", accounts.count)
        switch (accounts.count) {
        case 0:
            print("No account available! Please setup an account in the system settings");
            break;
        case 1:
            accountService.objectHandle = accounts.get(0, "accountServiceHandle");
            break;
        default:
            var component = Qt.createComponent(Qt.resolvedUrl("ui/AccountSelectorPage.qml"));
            var page = component.createObject(root, {accounts: accounts});
            page.accountSelected.connect(function(handle) { accountService.objectHandle = handle; pagestack.pop(); });
            pagestack.push(page);
        }
    }

    Connections {
        target: UserStore
        onUsernameChanged: {
            print("Logged in as user:", UserStore.username)
        }
    }

    Connections {
        target: NotesStore
        onNoteCreated: {
            var note = NotesStore.note(guid);
            print("note created:", note.guid);
            var component = Qt.createComponent(Qt.resolvedUrl("ui/EditNotePage.qml"));
            var page = component.createObject(pageStack)
            page.note = note;
            pagestack.push(page);
        }
    }

    PageStack {
        id: pagestack

        Tabs {
            id: rootTabs

            anchors.fill: parent

            Tab {
                title: i18n.tr("Notes")
                page: NotesPage {
                    id: notesPage
                }
            }

            Tab {
                title: i18n.tr("Notebooks")
                page: NotebooksPage {
                    id: notebooksPage
                }
            }

            Tab {
                title: i18n.tr("Reminders")
                page: RemindersPage {
                    id: remindersPage
                }
            }
        }
    }
}
