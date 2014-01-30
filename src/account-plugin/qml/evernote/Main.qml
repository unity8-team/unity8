import Evernote 0.1
import QtQuick 2.0
import Ubuntu.OnlineAccounts.Plugin 1.0

OAuthMain {
    creationComponent: OAuth {
        Connections {
            target: UserStore
            onUsernameChanged: saveUsername()
        }

        function completeCreation(reply) {
            EvernoteConnection.token = reply.AccessToken
            /* At this point the username is getting retrieved. Once that's
             * done, UserStore will notify that its "username" property has
             * been changed, and we'll continue from saveUsername(). */
        }

        function saveUsername() {
            account.updateDisplayName(UserStore.username)
            account.synced.connect(finished)
            account.sync()
        }
    }
}
