/*
 * Copyright 2016 Canonical Ltd.
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
 * Authored by Jonas G. Drange <jonas.drange@canonical.com>
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.Themes.Ambiance 1.3

Page {
    id: root
    property string name
    property string templateId

    signal requestDeletion(string templateId)
    signal requestRename(string templateId, string name)

    function deletionFailed() {
        PopupUtils.open(deletionFailed);
    }

    header: PageHeader {
        title: name
        flickable: flickable
    }

    Flickable {
        id: flickable
        anchors {
            fill: parent
            topMargin: units.gu(2)
        }
        boundsBehavior: (contentHeight > root.height) ?
                         Flickable.DragAndOvershootBounds :
                         Flickable.StopAtBounds
        contentHeight: contentItem.childrenRect.height

        Column {
            spacing: units.gu(2)
            anchors {
                left: parent.left
                right: parent.right
                margins: units.gu(3)
            }

            Label {
                id: nameLabel
                anchors.left: parent.left
                anchors.right: parent.right
                text: i18n.dtr("ubuntu-settings-components", "Fingerprint Name")
                font.weight: Font.Light
            }

            TextField {
                id: nameInput
                objectName: "nameInput"
                anchors.left: parent.left
                anchors.right: parent.right
                inputMethodHints: Qt.ImhNoPredictiveText
                style: TextFieldStyle {}
                text: name
                onTextChanged: {
                    if (text)
                        requestRename(templateId, text)
                }
            }

            Button {
                text: i18n.dtr("ubuntu-settings-components", "Delete Fingerprint")
                onClicked: requestDeletion(templateId)
                width: parent.width
            }
        }
    }

    Component {
        id: deletionFailed

        Dialog {
            id: deletionFailedDialog
            objectName: "fingerprintDeletionFailedDialog"
            text: i18n.dtr("ubuntu-settings-components",
                           "Sorry, the fingerprint could not be deleted.")

            Button {
                objectName: "fingerprintDeleteionFailedOk"
                onClicked: PopupUtils.close(deletionFailedDialog)
                text: i18n.dtr("ubuntu-settings-components", "OK")
            }
        }
    }
}
