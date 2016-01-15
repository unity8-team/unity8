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

Loader {
    id: root

    property bool showShortcut: true
    property var menuItemDelegate: undefined

    property string text: menuItemDelegate && menuItemDelegate.label || ""

    sourceComponent: {
        if (menuItemDelegate.isSeparator) {
            return separatorMenu;
        }
        if (menuItemDelegate.hasSubmenu) {
            return subMenu;
        }
        if (menuItemDelegate.isCheck || menuItemDelegate.isRadio) {
            return checkableMenu;
        }
        return standardMenu;
    }

    Component {
        id: separatorMenu

        Item {
            implicitHeight: units.dp(6)
            anchors {
                left: parent.left
                right: parent.right
            }

            Rectangle {
                height: units.dp(2)
                color: "#5D5D5D"
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Component {
        id: standardMenu

        Item {
            implicitWidth: column.implicitWidth + units.gu(2)
            implicitHeight: column.implicitHeight + units.gu(2)

            RowLayout {
                id: column
                spacing: units.gu(0.5)
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: units.gu(1)
                }

                Item {
                    Layout.preferredWidth: units.gu(1.5)
                    Layout.preferredHeight: units.gu(1.5)
                }

                Icon {
                    Layout.preferredWidth: units.gu(2)
                    Layout.preferredHeight: units.gu(2)
                    Layout.alignment: Qt.AlignVCenter

                    visible: menuItemDelegate && menuItemDelegate.icon || false
                    source: menuItemDelegate && menuItemDelegate.icon || ""
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: units.gu(5)

                    Label {
                        text: menuItemDelegate ? menuItemDelegate.label.htmlLabelFromMenuLabel(showShortcut) : ""
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                        color: enabled ? "#FFFFFF" : "#888888"
                        textFormat: Text.StyledText
                        fontSize: "small"
                    }

                    Label {
                        text: menuItemDelegate && menuItemDelegate.shortcut !== undefined ? menuItemDelegate.shortcut : ""
                        Layout.alignment: Qt.AlignRight
                        color: "#5D5D5D"
                        fontSize: "small"
                    }
                }
            }
        }
    }

    Component {
        id: subMenu

        Item {
            implicitWidth: column.implicitWidth + units.gu(2)
            implicitHeight: column.implicitHeight + units.gu(2)

            RowLayout {
                id: column
                spacing: units.gu(0.5)
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: units.gu(1)
                }

                Item {
                    Layout.preferredWidth: units.gu(1.5)
                    Layout.preferredHeight: units.gu(1.5)
                }

                Icon {
                    Layout.preferredWidth: units.gu(2)
                    Layout.preferredHeight: units.gu(2)
                    Layout.alignment: Qt.AlignVCenter

                    visible: menuItemDelegate && menuItemDelegate.icon || false
                    source: menuItemDelegate && menuItemDelegate.icon || ""
                }

                Label {
                    id: _title
                    text: menuItemDelegate && menuItemDelegate.label.htmlLabelFromMenuLabel(showShortcut) || ""
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                    color: enabled ? "#FFFFFF" : "#5D5D5D"
                    textFormat: Text.StyledText
                    fontSize: "small"
                }

                Icon {
                    id: chevron
                    visible: menuItemDelegate.hasSubmenu

                    Layout.preferredHeight: units.gu(1.5)
                    Layout.alignment: Qt.AlignVCenter
                    name: "chevron"
                    color: enabled ? "#FFFFFF" : "#5D5D5D"
                }
            }
        }
    }


    Component {
        id: checkableMenu

        Item {
            implicitWidth: column.implicitWidth + units.gu(2)
            implicitHeight: column.height + units.gu(2)

            RowLayout {
                id: column
                spacing: units.gu(0.5)
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: units.gu(1)
                }

                Item {
                    Layout.preferredWidth: units.gu(1.5)
                    Layout.preferredHeight: units.gu(1.5)
                    Layout.alignment: Qt.AlignVCenter

                    Icon {
                        anchors.fill: parent
                        visible: menuItemDelegate && menuItemDelegate.isToggled
                        name: "tick"
                        color: enabled ? "#FFFFFF" : "#5D5D5D"
                    }
                }

                Icon {
                    Layout.preferredWidth: units.gu(2)
                    Layout.preferredHeight: units.gu(2)
                    Layout.alignment: Qt.AlignVCenter

                    visible: menuItemDelegate && menuItemDelegate.icon
                    source: menuItemDelegate && menuItemDelegate.icon || ""
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: units.gu(5)

                    Label {
                        text: menuItemDelegate ? menuItemDelegate.label.htmlLabelFromMenuLabel(showShortcut) : ""
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                        color: enabled ? "#FFFFFF" : "#888888"
                        textFormat: Text.StyledText
                        fontSize: "small"
                    }

                    Label {
                        text: menuItemDelegate && menuItemDelegate.shortcut !== undefined ? menuItemDelegate.shortcut : ""
                        Layout.alignment: Qt.AlignRight
                        color: "#5D5D5D"
                        fontSize: "small"
                    }
                }
            }
        }
    }
}
