/*
 * Copyright (C) 2014-2015 Canonical, Ltd.
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
import Unity.Application 0.1 // For Mir singleton
import Ubuntu.Components 1.3
import Utils 0.1
import "../Components"
import "../Components/PanelState"
import "../ApplicationMenus"

Item {
    id: root

    property Item target
    property string appId
    property alias title: titleLabel.text
    property bool active: false
    property var menu: undefined

    signal close()
    signal minimize()
    signal maximize()

    QtObject {
        id: priv
        property real distanceX
        property real distanceY
        property bool dragging

        property var menuBar: menuBarLoader.item

        property bool enableMenus: root.active &&
                                   (!PanelState.decorationsVisible || PanelState.maximizedApplication !== appId) &&
                                   menuBar &&
                                   menuBar.hasChildren

        property bool shouldShowMenus : enableMenus &&
                                        (altFilter.longAltPressed || menuBarHover.containsMouse || menuBar.openItem !== undefined)
    }

    WindowKeysFilter {
        id: altFilter
        property bool altPressed: false
        property bool longAltPressed: false
        enabled: priv.enableMenus
        Keys.onPressed: {
            if (event.key === Qt.Key_Alt && !event.isAutoRepeat) {
                altPressed = true;
                longAltPressed = false;
                menuBarShortcutTimer.start();
                return;
            }            
            event.accepted = false;
        }
        Keys.onReleased: {
            if (event.key === Qt.Key_Alt) {
                menuBarShortcutTimer.stop();
                altPressed = false;
                longAltPressed = false;
                return;
            }            
            event.accepted = false
        }

        Timer {
            id: menuBarShortcutTimer
            interval: 200
            repeat: false
            onTriggered: {
                altFilter.longAltPressed = true;
            }
        }
    }

    // non rounded for bottom of decoration
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: units.gu(.5)
        color: "#292929"
    }

    // rounded for top of decoration
    Rectangle {
        anchors.fill: parent
        radius: units.gu(.5)
        color: "#292929"
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: units.gu(1)
            rightMargin: units.gu(1)
        }
        spacing: units.gu(3)

        WindowControlButtons {
            id: buttons
            anchors {
                top: parent.top
                bottom: parent.bottom
                topMargin: units.gu(0.5)
                bottomMargin: units.gu(0.5)
            }
            active: root.active
            onClose: root.close();
            onMinimize: root.minimize();
            onMaximize: root.maximize();
        }

        Item {
            Layout.preferredHeight: parent.height
            Layout.fillWidth: true

            MouseArea {
                id: menuBarHover
                hoverEnabled: true
                anchors.fill: parent
                onPressed: { mouse.accepted = false; } // just monitoring
            }

            Label {
                id: titleLabel
                objectName: "windowDecorationTitle"
                color: root.active ? "white" : "#5d5d5d"
                height: parent.height
                width: parent.width
                verticalAlignment: Text.AlignVCenter
                fontSize: "medium"
                font.weight: root.active ? Font.Light : Font.Normal
                elide: Text.ElideRight

                opacity: priv.shouldShowMenus ? 0 : 1
                Behavior on opacity { UbuntuNumberAnimation { } }
            }

            Loader {
                id: menuBarLoader
                objectName: "windowDecorationMenuBarLoader"
                anchors.bottom: parent.bottom
                height: parent.height
                width: parent.width
                sourceComponent: root.menu ? menuBarComponent : undefined
                Component {
                    id: menuBarComponent
                    MenuBar {
                        id: menuBar
                        height: menuBarLoader.height
                        focusWindow: root.target
                        menuModel: root.menu
                        enableMnemonic: altFilter.altPressed
                        enabled: priv.enableMenus
                    }
                }

                opacity: priv.shouldShowMenus ? 1 : 0
                Behavior on opacity { UbuntuNumberAnimation { } }
            }
        }
    }
}
