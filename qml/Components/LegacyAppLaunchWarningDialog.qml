/*
 * Copyright (C) 2015 Canonical, Ltd.
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

import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3

ShellDialog {
    id: root
    objectName: "legacyAppLaunchWarningDialog"

    property string appId

    signal cancel()

    Label {
        text: i18n.tr("Dock your device to open this app")
        fontSize: "large"
        wrapMode: Text.Wrap
        color: "#5D5D5D"
    }

    ThinDivider {}

    RowLayout {
        layoutDirection: Qt.RightToLeft

        Button {
            objectName: "cancelButton"
            text: i18n.tr("Cancel")
            color: UbuntuColors.lightGrey
            onClicked: {
                root.cancel();
            }
        }
    }
}
