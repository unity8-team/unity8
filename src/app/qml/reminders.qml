/*
 * Copyright: 2013 - 2014 Canonical, Ltd
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

Item {
    id: root

    // This is only for easier simulating form factors when running on desktop. Do NOT use this somewhere else.
    property bool tablet: true

    property bool narrowMode: root.width < units.gu(80)
    width: tablet ? units.gu(100) : units.gu(50)
    height: units.gu(75)

    function viewNote(note) {
        var component = Qt.createComponent(Qt.resolvedUrl("ui/NotePage.qml"));
        var page = component.createObject();
        page.note = note;
        if (root.narrowMode) {
            pagestack.push(page)
        } else {
            sideViewLoader.item.clear();
            sideViewLoader.item.push(page)
        }
        page.editNote.connect(function(note) {root.switchToEditMode(note)})
    }

    function switchToEditMode(note) {
        var component = Qt.createComponent(Qt.resolvedUrl("ui/EditNotePage.qml"));
        var page = component.createObject();
        page.note = note;
        if (root.narrowMode) {
            pagestack.pop();
            pagestack.push(page)
        } else {
            sideViewLoader.item.clear();
            sideViewLoader.item.push(page)
        }
        page.exitEditMode.connect(function() {
            if (root.narrowMode) {
                pagestack.pop();
            } else {
                sideViewLoader.item.pop();
            }
        })
    }


MainView {
    anchors { fill: null; left: parent.left; top: parent.top; bottom: parent.bottom }
    width: units.gu(50)
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "com.ubuntu.reminders"

    /*
     This property enables the application to change orientation
     when the device is rotated. The default is false.
    */
    //automaticOrientation: true


    // Temporary background color. This can be changed to other suitable backgrounds when we get official mockup designs
    backgroundColor: UbuntuColors.coolGrey

    property var accountPage;

    function openAccountPage(isChangingAccount) {
        if (accountPage) {
            accountPage.destroy(100)
        }
        var component = Qt.createComponent(Qt.resolvedUrl("ui/AccountSelectorPage.qml"));
        accountPage = component.createObject(root, {accounts: accounts, isChangingAccount: isChangingAccount});
        accountPage.accountSelected.connect(function(handle) { accountService.objectHandle = handle; pagestack.pop(); });
        pagestack.push(accountPage);
    }

    AccountServiceModel {
        id: accounts
        service: "evernote"
    }

    AccountService {
        id: accountService
        onObjectHandleChanged: authenticate(null);
        onAuthenticated: {
            if (EvernoteConnection.token && EvernoteConnection.token != reply.AccessToken) {
                EvernoteConnection.clearToken();
            }
            EvernoteConnection.token = reply.AccessToken;
        }
        onAuthenticationError: {
            console.log("Authentication failed, code " + error.code)
        }
    }

    Component.onCompleted: {
        pagestack.push(rootTabs)
        print("got accounts:", accounts.count)
        var accountName = accountPreference.accountName;
        if (accountName) {
            var i;
            for (i = 0; i < accounts.count; i++) {
                if (accounts.get(i, "displayName") == accountName) {
                    accountService.objectHandle = accounts.get(i, "accountServiceHandle");
                }
            }
        }
        if (!accountService.objectHandle) {
            switch (accounts.count) {
            case 0:
                print("No account available! Please setup an account in the system settings");
                break;
            case 1:
                accountService.objectHandle = accounts.get(0, "accountServiceHandle");
                break;
            default:
                openAccountPage(false);
            }
        }
    }

    Connections {
        target: UserStore
        onUsernameChanged: {
            print("Logged in as user:", UserStore.username);
            accountPreference.accountName = UserStore.username;
        }
    }

    Connections {
        target: NotesStore
        onNoteCreated: {
            var note = NotesStore.note(guid);
            print("note created:", note.guid);
            var component = Qt.createComponent(Qt.resolvedUrl("ui/EditNotePage.qml"));
            var page = component.createObject(pagestack)
            page.note = note;
            pagestack.push(page);
        }
    }

    PageStack {
        id: pagestack
        anchors { fill: null; left: parent.left; top: parent.top; bottom: parent.bottom }

        width: root.narrowMode ? root.width : units.gu(40)

        Tabs {
            id: rootTabs

            anchors.fill: parent

            Tab {
                title: i18n.tr("Notes")
                page: NotesPage {
                    id: notesPage
                    onNoteSelected: {
                        root.viewNote(note);
                    }
                    onOpenSearch: {
                        var component = Qt.createComponent(Qt.resolvedUrl("ui/SearchNotesPage.qml"))
                        var page = component.createObject();
                        pagestack.push(page)
                        page.noteSelected.connect(function(note) {root.viewNote(note)})
                    }
                }
            }

            Tab {
                title: i18n.tr("Notebooks")
                page: NotebooksPage {
                    id: notebooksPage

                    onOpenNotebook: {
                        var component = Qt.createComponent(Qt.resolvedUrl("ui/NotesPage.qml"))
                        var page = component.createObject();
                        print("opening note page for notebook", notebookGuid)
                        pagestack.push(page, {title: title/*, filter: notebookGuid*/});
                        page.noteSelected.connect(function(note) {root.viewNote(note)})
                        NotesStore.refreshNotes();
                    }
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

Loader {
    id: sideViewLoader
    anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
    width: root.width - pagestack.width

    sourceComponent: root.narrowMode ? null : sidePageStackComponent
}

Component {
    id: sidePageStackComponent
    MainView {
        anchors { fill: null; right: parent.right; top: parent.top; bottom: parent.bottom }
        width: root.width - units.gu(50)
        // objectName for functional testing purposes (autopilot-qt5)
        objectName: "mainView"

        // Note! applicationName needs to match the "name" field of the click manifest
        applicationName: "com.ubuntu.reminders"

        /*
         This property enables the application to change orientation
         when the device is rotated. The default is false.
        */
        //automaticOrientation: true


        // Temporary background color. This can be changed to other suitable backgrounds when we get official mockup designs
        backgroundColor: UbuntuColors.coolGrey

        function push(page) {
            pageStack.push(page);
        }

        function clear() {
            while (pageStack.depth > 0) {
                pageStack.pop();
            }
        }

        function pop() {
            pageStack.pop();
        }

        Label {
            anchors.centerIn: parent
            text: "Not note selected.\nSelect a note to see it in detail."
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            fontSize: "large"
            width: parent.width
        }

        PageStack {
            id: pageStack
        }
    }
}


}
