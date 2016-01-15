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
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3

MenuBase {
    id: root
    objectName: "menuPage"

    property bool vertical: false
    property alias delegateModel: repeater.model

    width: listView.width
    height: listView.height
    opensVertically: false
    enableMnemonic: focus

    Keys.onDownPressed: {
        listView.selectNext();
        event.accepted = true;
    }
    Keys.onUpPressed: {
        listView.selectPrevious();
        event.accepted = true;
    }

    Keys.onLeftPressed: {
        if (root.openItem !== undefined) {
            if (!focus) {
                // If we don't have the focus, then a child must.
                // Close the child and let our parent handle the left press
                root.closePopup(true);
                event.accepted = true;
                return;
            }
        }
        event.accepted = false;
    }
    Keys.onRightPressed: {
        if (listView.selectedItem) {
            if (listView.selectedItem.delegate.hasSubmenu) {
                root.open(listView.selectedItem, true, 0);
                event.accepted = true;
                return;
            }
        }
        event.accepted = false;
    }
    Keys.onReturnPressed: {
        if (listView.selectedItem) {
            if (listView.selectedItem.delegate.hasSubmenu) {
                root.open(listView.selectedItem, true, 0);
                event.accepted = true;
                return;
            } else {
                listView.selectedItem.delegate.activate();
                event.accepted = true;
            }
        }
    }

    function setSelectedItem(index) {
        if (repeater.count <= index) return;
        var item = repeater.itemAt(index);
        item.selected = true;
    }

    BorderImage {
        anchors {
            fill: root
            margins: -units.gu(1)
        }
        source: "../Stages/graphics/dropshadow2gu.sci"
        opacity: 0.3
    }

    Rectangle {
        anchors.fill: parent
        color: "#292929"
    }

    ColumnLayout {
        id: listView
        objectName: root.objectName+"-ListView"
        spacing: 0

        property var selectedItem: undefined

        function selectNext() {
            var delegate;
            var newIndex = 0;
            if (listView.selectedItem === undefined && repeater.count > 0) {
                while (repeater.count > newIndex) {
                    delegate = repeater.itemAt(newIndex++);
                    if (delegate.enabled) {
                        delegate.selected = true;
                        break;
                    }
                }
            } else if (listView.selectedItem !== undefined && repeater.count > 1) {
                var startIndex = (listView.selectedItem.ownIndex + 1) % repeater.count;
                newIndex = startIndex;
                do {
                    delegate = repeater.itemAt(newIndex);
                    if (delegate.enabled) {
                        delegate.selected = true;
                        break;
                    }
                    newIndex = (newIndex + 1) % repeater.count;
                } while (newIndex !== startIndex)
            }
        }

        function selectPrevious() {
            var delegate;
            var newIndex = repeater.count-1;
            if (listView.selectedItem === undefined && repeater.count > 0) {
                while (repeater.count > newIndex) {
                    delegate = repeater.itemAt(newIndex--);
                    if (delegate.enabled) {
                        delegate.selected = true;
                        break;
                    }
                }
            } else if (listView.selectedItem !== undefined && repeater.count > 1) {
                var startIndex = listView.selectedItem.ownIndex - 1;
                newIndex = startIndex;
                do {
                    if (newIndex < 0) newIndex = repeater.count - 1;
                    delegate = repeater.itemAt(newIndex--);
                    if (delegate.enabled) {
                        delegate.selected = true;
                        break;
                    }
                } while (newIndex !== startIndex)
            }
        }

        Repeater {
            id: repeater

            // This fixes the ordering issues with using repeater in Layouts.
            onCountChanged: {
                var i = 0;
                for (; i < repeater.count; i++) {
                    var item = repeater.itemAt(i)
                    item.parent = null;
                    item.parent = listView;
                }
            }
            onItemRemoved: {
                if (item.menuItem === listView.selectedItem) {
                    if  (root.openItem == item.menuItem) {
                        root.closePopup(true);
                    }
                    listView.selectedItem = undefined;
                }
            }

            delegate: MenuItemFactory {
                id: repeaterItem
                property bool selected: false
                enabled: model.delegate.sensitive && !model.delegate.isSeparator

                menuItemDelegate: model.delegate
                showShortcut: enableMnemonic

                Layout.fillWidth: true
                Layout.preferredHeight: repeaterItem.implicitHeight

                Rectangle {
                    visible: repeaterItem.selected
                    anchors.fill: parent
                    gradient: UbuntuColors.orangeGradient
                }

                property alias menuItem: _menuItem

                MenuItemBase {
                    id: _menuItem
                    objectName: root.objectName + "-menu" + index
                    property int ownIndex: index

                    anchors.fill: parent
                    delegate: model.delegate

                    mnemonicAction {
                        property string action: model.delegate.label.actionKeyFromMenuLabel()
                        enabled: enableMnemonic && repeaterItem.enabled
                        shortcut: action !== "" ? action : ""

                        onTriggered: {
                            if (model.delegate.hasSubmenu) {
                                root.open(menuItem, true, 0);
                            }
                            else {
                                model.delegate.activate();
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    z: 100

                    onEntered: {
                        repeaterItem.selected = true;
                    }
                    onClicked: {
                        if (model.delegate.hasSubmenu) {
                            root.open(menuItem, true);
                        }
                        else if (root.enabled) {
                            model.delegate.activate()
                        }
                    }
                }

                onSelectedChanged: {
                    if (selected)  {
                        listView.selectedItem = menuItem;
                        if (root.openItem !== menuItem) {
                            root.closePopup(true);
                            if (model.delegate.hasSubmenu) {
                                root.openWithDelay(menuItem, false);
                            }
                        }
                    }
                    else if (listView.selectedItem === menuItem) {
                        listView.selectedItem = undefined;
                        if  (root.openItem == menuItem) {
                            root.closePopup(true);
                        }
                    }
                }

                Connections {
                    target: listView
                    onSelectedItemChanged: {
                        if (repeaterItem.selected && (listView.selectedItem === undefined || listView.selectedItem !== menuItem)) {
                            repeaterItem.selected = false;
                            if (root.openItem == menuItem) {
                                root.closePopup(true);
                            }
                        }
                    }
                }

                Connections {
                    target: root
                    onOpenItemChanged: {
                        if (root.openItem == menuItem) {
                            repeaterItem.selected = true;
                        }
                    }
                }
            }
        }
    }
}
