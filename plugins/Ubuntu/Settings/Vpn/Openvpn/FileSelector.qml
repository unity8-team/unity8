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
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 1.1


ListItems.ItemSelector {
    id: root

    property string path

    property var activeTransfer: null

    ContentPeer {
        id: certSource
        contentType: ContentType.Documents
        handler: ContentHandler.Source
        selectionType: ContentTransfer.Single
    }

    ContentTransferHint {
        id: importHint
        anchors.fill: parent
        activeTransfer: root.activeTransfer
    }

    Connections {
        target: root.activeTransfer
        onStateChanged: {
            if (root.activeTransfer.state === ContentTransfer.Charged)
                console.warn(root.activeTransfer.items, root.activeTransfer.items[0].url);
                path = root.activeTransfer.items[0].url;
        }
    }

    model: [
        path ? path.split("/")[path.split("/").length - 1] : i18n.tr("None"),
        i18n.tr("Choose…")
    ]

    onDelegateClicked: {
        if (index === 1) {
            activeTransfer = certSource.request();
        }
    }
}
