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

    property bool enableMnemonic: false
    property bool opensVertically: true
    readonly property alias openItem: d._openItem
    property real submenuOffset: 0

    function open(menuItem, focus, focusIndex) {
        openDelayTimer.stop();

        if (d._openItem !== menuItem && menuItem.delegate.hasSubmenu) {
            d.closePopup();

            var menuPageComponent = Qt.createComponent("MenuPage.qml");

            if (menuPageComponent.status === Component.Ready) {
                d._requestedOpenItem = menuItem;
                d.popup = menuPageComponent.createObject(menuItem,
                                                         {
                                                             "objectName": root.objectName + "-subMenu" + menuItem.delegate.index,
                                                             "vertical": true,
                                                             "x": opensVertically ? submenuOffset : menuItem.width,
                                                             "y": opensVertically ? menuItem.height : submenuOffset,
                                                             "delegateModel": menuItem.delegate.submenuItems
                                                         });
            } else if (menuPageComponent.status === Component.Error) {
                console.log(menuPageComponent.errorString());
            }
        }
        if (focus && d.popup) d.popup.forceActiveFocus();
        if (focusIndex !== undefined && d.popup) d.popup.setSelectedItem(focusIndex);
    }

    function openWithDelay(menuItem, focus, index) {
        openDelayTimer.stop();
        if (d._openItem === menuItem) {
            open(menuItem, focus, index);
        } else {
            d._requestedOpenItem = menuItem;
            openDelayTimer.openFocus = focus;
            openDelayTimer.openIndex = index;
            openDelayTimer.restart();
        }
    }

    function closePopup(focus) {
        openDelayTimer.stop();
        if (openItem !== undefined) {
            d.closePopup();
        }
        if (focus) {
            forceActiveFocus();
        }
    }

    Timer {
        id: openDelayTimer

        property var openFocus
        property var openIndex

        interval: Constants.menuHoverOpenInterval
        onTriggered: {
            open(d._requestedOpenItem, openDelayTimer.openFocus, openDelayTimer.openIndex);
        }
    }

    QtObject {
        id: d
        property var _requestedOpenItem: undefined
        property var _openItem: undefined

        property QtObject popup: null
        onPopupChanged: {
            d._openItem = popup !== null ? _requestedOpenItem : undefined
        }

        signal closePopup
    }

    Connections {
        target: d
        onClosePopup: {
            if (d.popup) {
                // recusive close to preserve focusing
                d.popup.closePopup(false);
                d.popup.visible = false;
                d.popup.destroy();
                d.popup = null;

                d._openItem = undefined;
                d._requestedOpenItem = undefined;
            }
        }
    }
}
