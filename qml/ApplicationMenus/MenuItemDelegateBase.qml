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
import Utils 0.1

Item {
    id: root
    property alias menuModel: subMenuRepeater.model
    readonly property alias submenuItems: submenuDelegates
    property var focusWindow: undefined

    ListModel {
        id: submenuDelegates
    }

    Repeater {
        id: subMenuRepeater

        onItemAdded: {
            submenuDelegates.insert(index, { delegate: item.item });
        }
        onItemRemoved: {
            for (var i = 0; i < submenuDelegates.count; i++) {
                if (item.item === submenuDelegates.get(i).delegate) {
                    submenuDelegates.remove(i, 1);
                    return;
                }
            }
        }
        onCountChanged: {
            if (count == 0) {
                submenuDelegates.clear();
            }
        }

        delegate: Loader {
            id: loader
            source: "MenuItemDelegate.qml"

            property int modelIndex: index

            Binding {
                target: loader.item
                property: "index"
                value: loader.modelIndex
            }
            Binding {
                target: loader.item
                property: "menuModel"
                value: model.hasSubmenu ? menuModel.submenu(loader.modelIndex) : undefined
            }
            Binding {
                target: loader.item
                property: "menuData"
                value: model
            }
            Binding {
                target: loader.item
                property: "focusWindow"
                value: focusWindow
            }
            Connections {
                target: loader.item
                onActivate: menuModel.activate(loader.modelIndex)
            }
        }
    }
}
