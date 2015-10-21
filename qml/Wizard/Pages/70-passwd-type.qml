/*
 * Copyright (C) 2014-2015 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.3
import Ubuntu.Components 1.2
import Ubuntu.SystemSettings.SecurityPrivacy 1.0
import ".." as LocalComponents

/**
 * One quirk with this page: we don't actually set the password.  We avoid
 * doing it here because the user can come back to this page and change their
 * answer.  We don't run as root, so if we did set the password immediately,
 * we'd need to prompt for their previous password when they came back and
 * changed their answer.  Which is silly UX.  So instead, we just keep track
 * of their choice and set the password at the end (see Pages.qml).
 * Setting the password shouldn't fail, since Ubuntu Touch has loose password
 * requirements, but we'll check what we can here.  Ideally we'd be able to ask
 * the system if a password is legal without actually setting that password.
 */

LocalComponents.Page {
    id: passwdPage
    objectName: "passwdPage"

    title: i18n.tr("Lock Screen")
    forwardButtonSourceComponent: forwardButton

    function indexToMethod(index) {
        if (index === 0 || index === 1)
            return UbuntuSecurityPrivacyPanel.Passphrase;
        else if (index === 2)
            return UbuntuSecurityPrivacyPanel.Passcode;
        else
            return UbuntuSecurityPrivacyPanel.Swipe;
    }

    Component.onCompleted: {
        if (root.password !== "") // the user has set a password as part of the previous page
            selector.currentIndex = 0;
        else
            selector.currentIndex = 1;
    }

    Item {
        id: column
        anchors.fill: content
        anchors.topMargin: customMargin

        Label {
            id: infoLabel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: leftMargin
            wrapMode: Text.Wrap
            text: i18n.tr("Choose lock screen security")
            color: textColor
            fontSize: "small"
            font.weight: Font.Light
        }

        Rectangle {
            id: divider
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: infoLabel.bottom
            anchors.topMargin: units.gu(3)
            height: units.dp(1)
            color: dividerColor
        }

        ListView {
            id: selector
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: divider.bottom
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            height: childrenRect.height

            // this is the order we want to display it; cf indexToMethod()
            model: [UbuntuSecurityPrivacyPanel.Passphrase, UbuntuSecurityPrivacyPanel.Passphrase,
                    UbuntuSecurityPrivacyPanel.Passcode, UbuntuSecurityPrivacyPanel.Swipe]

            delegate: ListItem {
                id: itemDelegate
                readonly property bool isCurrent: index === ListView.view.currentIndex
                highlightColor: backgroundColor
                divider.colorFrom: dividerColor
                divider.colorTo: backgroundColor
                Label {
                    id: methodLabel
                    objectName: "passwdDelegate" + index
                    anchors.verticalCenter: parent.verticalCenter;
                    anchors.left: parent.left
                    anchors.leftMargin: leftMargin
                    fontSize: "medium"
                    color: textColor
                    font.weight: itemDelegate.isCurrent ? Font.Normal : Font.Light
                    text: {
                        switch (index) {
                        case 0:
                            return i18n.ctr("Label: Type of security method", "Device account password");
                        case 1:
                            return i18n.ctr("Label: Type of security method", "New password");
                        case 2:
                            return i18n.ctr("Label: Type of security method", "Passcode");
                        case 3:
                            return i18n.ctr("Label: Type of security method", "Swipe");
                        }
                    }
                }

                Image {
                    anchors {
                        right: parent.right;
                        verticalCenter: parent.verticalCenter;
                        rightMargin: rightMargin
                    }
                    fillMode: Image.PreserveAspectFit
                    height: units.gu(1.5)

                    source: "data/Tick@30.png"
                    visible: itemDelegate.isCurrent
                }

                onClicked: {
                    selector.currentIndex = index;
                    print("Current method: " + indexToMethod(index));
                }
            }
        }

        Rectangle {
            id: divider2
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: selector.bottom
            height: units.dp(1)
            color: dividerColor
        }
    }

    Component {
        id: forwardButton
        LocalComponents.StackButton {
            text: i18n.tr("Next")
            onClicked: {
                var method = indexToMethod(selector.currentIndex);
                root.passwordMethod = method;
                print("Current method: " + root.passwordMethod);

                if (method === UbuntuSecurityPrivacyPanel.Passphrase) { // any password
                    if (selector.currentIndex == 1)
                        pageStack.load(Qt.resolvedUrl("password-set.qml")); // let the user choose a new password
                    else
                        pageStack.next(); // got the password already, go next page
                } else if (method === UbuntuSecurityPrivacyPanel.Passcode) { // passcode
                    pageStack.load(Qt.resolvedUrl("passcode-set.qml"));
                } else { //swipe
                    pageStack.next();
                }
            }
        }
    }
}