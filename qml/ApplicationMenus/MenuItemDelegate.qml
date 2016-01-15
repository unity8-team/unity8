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
import QtQuick.Controls 1.3 as Controls
import Utils 0.1 as UnityUtils

MenuItemDelegateBase {
    id: root
    property var index: undefined
    property var menuData: undefined

    readonly property string label: menuData ? menuData.label : ""
    readonly property string action: menuData ? menuData.action : ""
    readonly property string icon: menuData ? menuData.icon : ""
    readonly property var shortcut: menuData ? menuData.shortcut : undefined
    readonly property bool sensitive: menuData ? menuData.sensitive : false
    readonly property bool hasSubmenu: menuData ? menuData.hasSubmenu : false
    readonly property bool isSeparator: menuData ? menuData.isSeparator : false
    readonly property bool isCheck: menuData ? menuData.isCheck : false
    readonly property bool isRadio: menuData ? menuData.isRadio : false
    readonly property bool isToggled: menuData ? menuData.isToggled : false

    signal activate()

    UnityUtils.ShortcutAction {
        shortcut: root.shortcut
        target: focusWindow ? focusWindow : null

        onTriggered: {
            if (root.enabled) {
                activate();
            }
        }
    }
}
