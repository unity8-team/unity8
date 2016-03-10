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
import Ubuntu.Components.ListItems 1.3 as ListItems

ListItems.ItemSelector {
    property string path
    property string chooseLabel: i18n.tr("Choose…")

    property var __dialog

    // FIXME: workaround for lp:1498683. Resetting the model is the only
    // thing that will make selectedIndex = 0 work.
    function resetModel () {
        var m = [];
        model = m;
        m.push(i18n.tr("None"));

        if (path) {
            m.push(path);
        }

        m.push(chooseLabel);
        model = m;

        currentlyExpanded = false;
        if (path) {
            selectedIndex = 1;
        }
    }

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
        destroyDialog();
        resetModel();
    }

    function pathRejected() {
        destroyDialog();
        resetModel();
    }

    Component.onCompleted: resetModel()

    delegate: OptionSelectorDelegate {
        objectName: "vpnFileSelectorItem" + index
        text: {
            if (modelData[0] == "/") {
                return path.split("/")[path.split("/").length - 1];
            } else {
                return modelData;
            }
        }
    }

    onDelegateClicked: {
        if (index === 0) {
            path = "";
        } else if (index === model.length - 1) {
           createDialog();
        } else {
            path = model[index];
        }
    }
}
