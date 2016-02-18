/*
 * Copyright (C) 2015 Canonical Ltd.
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
import Ubuntu.Components.ListItems 1.3 as ListItems

ListItems.ItemSelector {
    property string path

    property var __dialog

    function createDialog() {
        __dialog = PopupUtils.open(fileDialogComponent)
        __dialog.accept.connect(pathAccepted)
        __dialog.reject.connect(pathRejected)
    }

    function destroyDialog() {
        __dialog.accept.disconnect(pathAccepted)
        __dialog.reject.disconnect(pathRejected)
        PopupUtils.close(__dialog)
    }

    function pathAccepted(newPath) {
        path = newPath
        destroyDialog()
    }

    function pathRejected() {
        destroyDialog()
    }


    model: [
        path ? path.split("/")[path.split("/").length - 1] : i18n.tr("None"),
        i18n.tr("Choose…")
    ]

    onDelegateClicked: {
        if (index === 1) {
           createDialog();
        }
    }
}
