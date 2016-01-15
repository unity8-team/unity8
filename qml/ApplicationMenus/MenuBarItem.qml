/*
 * Copyright 2015 Canonical Ltd.
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
 */

import QtQuick 2.4
import Ubuntu.Settings.Menus 0.1 as Menus
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1

import "AppMenuUtils.js" as AppMenuUtils

Item {
    id: root
    property var menuItemDelegate: undefined
    property bool enableMnemonic: false

    implicitWidth: column.implicitWidth
    implicitHeight: column.height

    RowLayout {
        id: column
        spacing: units.gu(1)
        anchors {
            centerIn: parent
        }

        Icon {
            Layout.preferredWidth: units.gu(2)
            Layout.preferredHeight: units.gu(2)
            Layout.alignment: Qt.AlignVCenter

            visible: menuItemDelegate && menuItemDelegate.icon
            source: menuItemDelegate && menuItemDelegate.icon || ""
        }

        Label {
            id: _title
            text: menuItemDelegate.label.htmlLabelFromMenuLabel(enableMnemonic) || ""
            horizontalAlignment: Text.AlignLeft
            color: enabled ? "white" : "#5d5d5d"
        }
    }
}
