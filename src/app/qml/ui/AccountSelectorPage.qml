import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1
import Ubuntu.OnlineAccounts 0.1
import Evernote 0.1

Page {
    id: root
    title: "Select Evernote account"

    AccountServiceModel {
        id: accounts
        // Use the Evernote service
        service: "evernote"
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
                            NotesStore.token = reply.AccessToken;
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
        }

    }
}
