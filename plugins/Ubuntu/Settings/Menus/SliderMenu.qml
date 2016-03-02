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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem

ListItem.Empty {
    id: menu

    property alias minimumValue: slider.minimumValue
    property alias maximumValue: slider.maximumValue
    property alias live: slider.live
    property double value: 0.0

    property alias minIcon: leftButton.source
    property alias maxIcon: rightButton.source

    signal updated(real value)

    property QtObject d: QtObject {
        property bool enableValueConnection: true
        property double originalValue: 0.0

        property Connections connections: Connections {
            target: menu
            onValueChanged: {
                if (!d.enableValueConnection) return;

                d.originalValue = menu.value;

                d.checkValueMinMax();
            }

            // need to re-assert the reported value to the requested value.
            onMinimumValueChanged: {
                if (menu.value !== d.originalValue) {
                    menu.value = d.originalValue;
                } else {
                    d.checkValueMinMax();
                }
            }
            onMaximumValueChanged: {
                if (menu.value !== d.originalValue) {
                    menu.value = d.originalValue;
                } else {
                    d.checkValueMinMax();
                }
            }
        }

        function lockValue() {
            if (!d.enableValueConnection) return false;
            d.enableValueConnection = false;
            return true;
        }

        function unlockValue(oldValue) {
            d.enableValueConnection = oldValue;
        }

        function checkValueMinMax() {
            var oldEnable = lockValue();
            if (!oldEnable) return;

            // Can't rely on binding. Slider value is assigned by user slide.
            if (menu.value < minimumValue) {
                slider.value = minimumValue;
                menu.value = minimumValue;
            } else if (menu.value > maximumValue) {
                slider.value = maximumValue;
                menu.value = maximumValue;
            } else if (slider.value != menu.value) {
                slider.value = menu.value;
            }

            unlockValue(oldEnable);
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

            Icon {
                id: leftButton
                objectName: "leftButton"
                visible: source != ""
                anchors.left: row.left
                anchors.verticalCenter: row.verticalCenter
                height: slider.height - units.gu(2)
                width: height
                color: theme.palette.selected.backgroundText

                MouseArea {
                    anchors.fill: parent
                    onClicked: slider.value = slider.minimumValue
                }

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
                    target: slider
                    onValueChanged: {
                        var oldEnable = d.lockValue();
                        if (!oldEnable) return;

                        menu.value = slider.value;
                        d.originalValue = menu.value;
                        menu.updated(slider.value);

                        d.unlockValue(oldEnable);
                    }
                }
            }

            Icon {
                id: rightButton
                objectName: "rightButton"
                visible: source != ""
                anchors.right: row.right
                anchors.verticalCenter: row.verticalCenter
                height: slider.height - units.gu(2)
                width: height
                color: theme.palette.selected.backgroundText

                MouseArea {
                    anchors.fill: parent
                    onClicked: slider.value =  slider.maximumValue
                }
            }
        }
    }
}
