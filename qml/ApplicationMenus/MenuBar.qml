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
    objectName: "menuBar"

    property var focusWindow: undefined
    property alias menuModel: rootDelegate.menuModel
    implicitWidth: listView.width
    readonly property bool hasChildren: repeater.count > 0
    submenuOffset: -units.gu(1)

    function close() {
        closePopup();
        listView.selectedItem = undefined;
    }

    FocusScope {
        id: scope
        anchors {
            left: parent.left
        }
        width: listView.width
        height: parent.height

        Keys.onLeftPressed: listView.selectPrevious()
        Keys.onRightPressed: listView.selectNext()
        Keys.onEscapePressed: {
            focus = false;
            if (focusWindow !== undefined) {
                focusWindow.forceActiveFocus();
            }
        }

        onFocusChanged: {
            if (!focus && root.openItem) {
                root.close();
            }
        }

        InverseMouseArea {
            enabled: root.openItem !== undefined
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            anchors.fill: parent

            onPressed: {
                // stop the inverse mouse area stealing events from mouse areas under.
                mouse.accepted = false;
                root.close();
            }
        }

        MenuItemDelegateBase {
            id: rootDelegate
            focusWindow: root.focusWindow
        }

        Row {
            id: listView
            anchors.left: parent.left
            height: parent.height
            spacing: units.gu(2)

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
                model: rootDelegate.submenuItems

                MenuBarItem {
                    id: repeaterItem
                    height: listView.height

                    enableMnemonic: root.enableMnemonic
                    menuItemDelegate: model.delegate

                    property int modelIndex: index
                    property bool selected: false
                    enabled: model.delegate.sensitive && !model.delegate.isSeparator

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            leftMargin: -units.gu(1)
                            rightMargin: -units.gu(1)
                        }
                        height: units.dp(4)
                        color: "#E95420"
                        visible: root.openItem == menuItem
                    }

                    MenuItemBase {
                        id: menuItem
                        objectName: root.objectName + "-menu" + index
                        property int ownIndex: index

                        anchors.fill: parent
                        delegate: model.delegate

                        mnemonicAction {
                            property string action: model.delegate.label.actionKeyFromMenuLabel()
                            enabled: enableMnemonic && repeaterItem.enabled
                            shortcut: action !== "" ? "Alt+" + action : ""

                            onTriggered: {
                                if (model.delegate.hasSubmenu) {
                                    root.open(menuItem, true);
                                }
                                else {
                                    model.delegate.activate();
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: titleMouseArea
                        anchors.fill: parent
                        hoverEnabled: listView.selectedItem !== undefined

                        onEntered: {
                            if (listView.selectedItem !== undefined && !repeaterItem.selected) {
                                repeaterItem.selected = true;
                            }
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
                            if (model.delegate.hasSubmenu && root.openItem !== menuItem) {
                                root.open(menuItem, true);
                            }
                        }
                        else if (listView.selectedItem === menuItem) {
                            listView.selectedItem = undefined;
                            if  (root.openItem == menuItem) {
                                root.closePopup();
                            }
                        }
                    }

                    Connections {
                        target: listView
                        onSelectedItemChanged: {
                            if (repeaterItem.selected && (listView.selectedItem === undefined || listView.selectedItem !== menuItem)) {
                                repeaterItem.selected = false;
                                if (root.openItem == menuItem) {
                                    root.closePopup();
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
}
