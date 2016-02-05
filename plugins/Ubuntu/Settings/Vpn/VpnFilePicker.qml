/*
 * Copyright (C) 2016 Canonical Ltd.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 0.1

PopupBase  {
    id: picker

    signal fileImportSignal (var file)
    property var activeTransfer

    Rectangle {
        anchors.fill: parent

        ContentTransferHint {
            id: transferHint
            anchors.fill: parent
            activeTransfer: picker.activeTransfer
        }

        ContentStore {
            id: appStore
            scope: ContentScope.App
        }

        ContentPeerPicker {
            id: peerPicker
            anchors.fill: parent
            visible: true
            contentType: ContentType.Documents
            handler: ContentHandler.Source
            onPeerSelected: {
                peer.selectionType = ContentTransfer.Single;
                picker.activeTransfer = peer.request(appStore);
            }
            onCancelPressed: PopupUtils.close(picker)
        }
    }

    Connections {
        target: picker.activeTransfer ? picker.activeTransfer : null
        onStateChanged: {
            if (picker.activeTransfer.state === ContentTransfer.Charged) {
                if (picker.activeTransfer.items.length > 0) {
                    var fileUrl = picker.activeTransfer.items[0].url;
                    picker.fileImportSignal(
                        fileUrl.toString().replace("file://", "")
                    );
                    PopupUtils.close(picker);
                }
            } else if (picker.activeTransfer.state === ContentTransfer.Aborted){
                picker.fileImportSignal(false);
                PopupUtils.close(picker);
            }
        }
    }
}
