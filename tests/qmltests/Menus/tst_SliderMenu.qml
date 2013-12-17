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
import QtTest 1.0
import Ubuntu.Components 0.1
import Ubuntu.Settings.Menus 0.1
import "../utils.js" as UtilsJS

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

    TestCase {
        name: "SliderMenu"
        when: windowShown

        function init() {
            sliderMenu.value = 0;
        }

        function test_minimumValue() {
            sliderMenu.value = 0;
            compare(sliderMenu.value, 0, "Minimum value not functioning");

            sliderMenu2.value = 0;
            compare(sliderMenu2.value, 20, "Minimum value not functioning");
        }

        function test_maximumValue() {
            sliderMenu.value = 100;
            compare(sliderMenu.value, 100, "Minimum value not functioning");

            sliderMenu2.value = 100;
            compare(sliderMenu2.value, 80, "Maximum value not functioning");
        }

        // simulates dragging the slider to a value
        function test_setSliderValue() {
            var slider = UtilsJS.findChild(sliderMenu, "slider");
            verify(slider !== undefined);

            slider.value = 20;
            compare(sliderMenu.value, 20, "Slider value not updating menu value");
        }

        // simulates dragging the slider to a value
        function test_setMenuValue() {
            var slider = UtilsJS.findChild(sliderMenu, "slider");
            verify(slider !== undefined);

            sliderMenu.value = 20;
            compare(slider.value, 20, "Menu value not updating slider value");
        }

        // simulates clicking the min/max buttons
        function test_minmaxButtons() {
            var slider = UtilsJS.findChild(sliderMenu, "slider");
            verify(slider !== undefined);

            var leftButton = UtilsJS.findChild(sliderMenu, "leftButton");
            verify(leftButton !== undefined);

            var rightButton = UtilsJS.findChild(sliderMenu, "rightButton");
            verify(rightButton !== undefined);

            mouseClick(leftButton, leftButton.width / 2, leftButton.height / 2);
            compare(slider.value, sliderMenu.minimumValue, "Min button not updating menu value");

            mouseClick(rightButton, rightButton.width / 2, rightButton.height / 2);
            compare(slider.value, sliderMenu.maximumValue, "Max button not updating menu value");
        }
    }
}
