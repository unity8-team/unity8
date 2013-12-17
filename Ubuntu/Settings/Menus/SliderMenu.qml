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
 * Authored by Andrea Cimitan <andrea.cimitan@canonical.com>
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem

ListItem.Empty {
    id: menu

    property alias minimumValue: slider.minimumValue
    property alias maximumValue: slider.maximumValue
    property alias live: slider.live
    property double value: 0.0

    property alias minIcon: leftButton.iconSource
    property alias maxIcon: righButton.iconSource

    signal updated(real value)

    property QtObject d: QtObject {
        property bool enableValueConnection: true

        property Connections connections: Connections {
            target: d.enableValueConnection ? menu : null
            onValueChanged: {
                var oldEnable = d.enableValueConnection
                d.enableValueConnection = false;

                // Can't rely on binding. Slider value is assigned by user slide.
                if (menu.value < minimumValue) {
                    slider.value = minimumValue;
                    menu.value = minimumValue;
                } else if (menu.value > maximumValue) {
                    slider.value = maximumValue;
                    menu.value = maximumValue;
                } else {
                    slider.value = menu.value;
                }

                d.enableValueConnection = oldEnable;
            }
        }
    }

    implicitHeight: column.height + units.gu(1.5)

    Column {
        id: column
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
            leftMargin: menu.__contentsMargins
            rightMargin: menu.__contentsMargins
        }
        height: childrenRect.height
        spacing: units.gu(0.5)

        Label {
            id: label
            text: menu.text
            anchors {
                left: parent.left
                right: parent.right
            }
            visible: text != ""
        }

        Item {
            id: row
            anchors {
                left: parent.left
                right: parent.right
            }
            height: slider.height

            Button {
                id: leftButton
                anchors.left: row.left
                anchors.verticalCenter: row.verticalCenter
                height: slider.height - units.gu(2)
                width: height
                color: "transparent"

                onClicked: slider.value = 0.0
            }

            Slider {
                id: slider
                objectName: "slider"
                anchors {
                    left: leftButton.visible ? leftButton.right : row.left
                    right: rightButton.visible ? rightButton.left : row.right
                    leftMargin: leftButton.visible ? units.gu(0.5) : 0
                    rightMargin: rightButton.visible ? units.gu(0.5) : 0
                }
                live: true

                Component.onCompleted: {
                    value = menu.value
                }

                minimumValue: 0
                maximumValue: 100

                // FIXME - to be deprecated in Ubuntu.Components.
                // Use this to disable the label, since there is not way to do it on the component.
                function formatValue(v) {
                    return "";
                }

                Connections {
                    target: d.enableValueConnection ? slider : null
                    onValueChanged: {
                        var oldEnable = d.enableValueConnection;
                        d.enableValueConnection = false;

                        menu.value = slider.value;
                        menu.updated(slider.value);

                        d.enableValueConnection = oldEnable;
                    }
                }
            }

            Button {
                id: rightButton
                anchors.right: row.right
                anchors.verticalCenter: row.verticalCenter
                height: slider.height - units.gu(2)
                width: height
                color: "transparent"

                onClicked: slider.value = 100.0
            }
        }
    }
}
