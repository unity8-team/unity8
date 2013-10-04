/*
 * Copyright 2013 Canonical Ltd.
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
 *
 * Authors:
 *      Renato Araujo Oliveira Filho <renato@canonical.com>
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem

ListItem.Empty {
    id: menu
    implicitHeight: units.gu(5.5)

    property bool checked: false
    property bool secure: false
    property bool adHoc: false
    property int signalStrength: 0
    property alias text: label.text

    __acceptEvents: false

    CheckBox {
        id: checkbox
        property bool enableCheckConnection: true

        height: units.gu(3)
        width: units.gu(3)

        anchors {
            left: parent.left
            leftMargin: menu.__contentsMargins
            verticalCenter: parent.verticalCenter
        }

        // FIXME : should use Checkbox.toggled signal
        // lp:~nick-dedekind/ubuntu-ui-toolkit/checkbox.toggled
        onCheckedChanged: {
            if (!enableCheckConnection) {
                return;
            }
            var oldEnable = enableCheckConnection;
            enableCheckConnection = false;

            menu.checked = checked;
            menu.triggered(menu.checked);

            enableCheckConnection = oldEnable;
        }

        Connections {
            target: menu
            onCheckedChanged: {
                if (!checkbox.enableCheckConnection) {
                    return;
                }
                var oldEnable = checkbox.enableCheckConnection;
                checkbox.enableCheckConnection = false;

                checkBoxActive.checked = menu.checked;

                checkbox.enableCheckConnection = oldEnable;
            }
        }

        Connections {
            target: menu.__mouseArea
            onClicked: {
                checkbox.clicked();
            }
        }
    }

    Image {
        id: iconSignal

        width: height
        height: Math.min(units.gu(5), parent.height - units.gu(1))
        anchors {
            left: checkbox.right
            leftMargin: units.gu(1)
            verticalCenter: parent.verticalCenter
        }

        source: {
            var imageName = "nm-signal-100"

            if (adHoc) {
                imageName = "nm-adhoc";
            } else if (signalStrength == 0) {
                imageName = "nm-signal-00";
            } else if (signalStrength <= 25) {
                imageName = "nm-signal-25";
            } else if (signalStrength <= 50) {
                imageName = "nm-signal-50";
            } else if (signalStrength <= 75) {
                imageName = "nm-signal-75";
            }
            return "image://theme/" + imageName;
        }
    }

    Label {
        id: label
        anchors {
            left: iconSignal.right
            leftMargin: units.gu(1)
            verticalCenter: parent.verticalCenter
            right: iconSecure.visible ? iconSecure.left : parent.right
            rightMargin: menu.__contentsMargins
        }
        elide: Text.ElideRight
        opacity: label.enabled ? 1.0 : 0.5
    }

    Image {
        id: iconSecure
        visible: secure
        source: "artwork/secure.svg"

        width: height
        height: Math.min(units.gu(4), parent.height - units.gu(1))
        anchors {
            right: parent.right
            rightMargin: units.gu(1)
            verticalCenter: parent.verticalCenter
        }
    }
}
