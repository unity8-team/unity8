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
import QtTest 1.0
import Ubuntu.Test 0.1
import Ubuntu.Settings.Menus 0.1

Item {
    width: units.gu(42)
    height: units.gu(75)

    Flickable {
        id: flickable

        anchors.fill: parent
        contentWidth: column.width
        contentHeight: column.height

        Item {
            id: column

            width: flickable.width
            height: childrenRect.height

            SliderMenu {
                id: sliderMenu
                text: i18n.tr("Slider")
            }

            SliderMenu {
                id: sliderMenu2
                minimumValue: 20
                maximumValue: 80
                value: 20
                anchors.top: sliderMenu.bottom
                minIcon: Qt.resolvedUrl("../../artwork/avatar.png")
                maxIcon: Qt.resolvedUrl("../../artwork/rhythmbox.png")
            }
        }
    }

    UbuntuTestCase {
        name: "SliderMenu"
        when: windowShown

        function init() {
            sliderMenu.minimumValue = 0;
            sliderMenu.maximumValue = 100;
            sliderMenu.value = 0;
        }

        function test_minimumValue_data() {
            return [
                { tag: "less", minimum: 20, value: 0, expected: 20 },
                { tag: "equal", minimum: 0, value: 0, expected: 0 },
                { tag: "greater", minimum: 0, value: 20, expected: 20 },
            ];
        }

        function test_minimumValue(data) {
            sliderMenu.minimumValue = data.minimum;
            sliderMenu.value = data.value;
            compare(sliderMenu.value, data.expected, "Minimum value (" + data.minimum + ") not functioning");
        }

        function test_maximumValue_data() {
            return [
                { tag: "less", maximum: 80, value: 100, expected: 80 },
                { tag: "equal", maximum: 100, value: 100, expected: 100 },
                { tag: "greater", maximum: 100, value: 120, expected: 100 },
            ];
        }

        function test_maximumValue(data) {
            sliderMenu.maximumValue = data.maximum;
            sliderMenu.value = data.value;
            compare(sliderMenu.value, data.expected, "Maximum value (" + data.minimum + ") not functioning");
        }

        // simulates dragging the slider to a value
        function test_setSliderValue() {
            var slider = findChild(sliderMenu, "slider");
            verify(slider !== undefined);

            slider.value = 20;
            compare(sliderMenu.value, 20, "Slider value not updating menu value");
        }

        // simulates dragging the slider to a value
        function test_setMenuValue() {
            var slider = findChild(sliderMenu, "slider");
            verify(slider !== undefined);

            sliderMenu.value = 20;
            compare(slider.value, 20, "Menu value not updating slider value");
        }

        function test_updateMinimumValue_data() {
            return [
                { tag: "less", originalMinimum: 20, value: 0, newMinimum: 0 },
                { tag: "greater", originalMinimum: 0, value: 20, newMinimum: 20 },
            ];
        }

        // tests that changing the Minimum value will update the value if originally set lower
        function test_updateMinimumValue(data) {
            sliderMenu.minimumValue = data.originalMinimum;
            sliderMenu.value = data.value;
            compare(sliderMenu.value, data.originalMinimum > data.value ? sliderMenu.minimumValue : data.value);

            sliderMenu.minimumValue = data.newMinimum;
            compare(sliderMenu.value, data.value, "Minimum value (" + data.newMinimum + ") should update the value if originally set lower");
        }

        function test_updateMaximumValue_data() {
            return [
                { tag: "less", originalMaximum: 100, value: 80, newMaximum: 80 },
                { tag: "greater", originalMaximum: 80, value: 100, newMaximum: 100 },
            ];
        }

        // tests that changing the Maximum value will update the value if originally set higher
        function test_updateMaximumValue(data) {
            sliderMenu.maximumValue = data.originalMaximum;
            sliderMenu.value = data.value;
            compare(sliderMenu.value, data.originalMaximum < data.value ? sliderMenu.maximumValue : data.value);

            sliderMenu.maximumValue = data.newMaximum;
            compare(sliderMenu.value, data.value, "Maximum value (" + data.newMaximum + ") should update the value if originally set higher");
        }

        // simulates clicking the min/max buttons
        function test_minmaxButtons() {
            var slider = findChild(sliderMenu2, "slider");
            verify(slider !== undefined);

            var leftButton = findChild(sliderMenu2, "leftButton");
            verify(leftButton !== undefined);

            var rightButton = findChild(sliderMenu2, "rightButton");
            verify(rightButton !== undefined);

            mouseClick(leftButton, leftButton.width / 2, leftButton.height / 2);
            compare(slider.value, sliderMenu2.minimumValue, "Min button not updating menu value");

            mouseClick(rightButton, rightButton.width / 2, rightButton.height / 2);
            compare(slider.value, sliderMenu2.maximumValue, "Max button not updating menu value");
        }
    }
}
