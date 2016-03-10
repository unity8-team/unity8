/*
 * Copyright 2015 Canonical Ltd.
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
import QtTest 1.0
import Ubuntu.Test 0.1
import Ubuntu.Settings.Components 0.1 as USC
import Ubuntu.Settings.Menus 0.1 as USM
import Ubuntu.Components 1.3

Item {
    id: root
    width: units.gu(60)
    height: units.gu(70)

    QtObject {
        id: switchBackend

        property bool checked: false
        property bool inSync: checked === switchControl.checked

        property Timer timer: Timer {
            interval: 2000
            onTriggered: switchBackend.checked = !switchBackend.checked
        }
    }

    QtObject {
        id: checkBackend

        property bool checked: false
        property bool inSync: checked === checkControl.checked

        property Timer timer: Timer {
            interval: 2000
            onTriggered: checkBackend.checked = !checkBackend.checked
        }
    }

    QtObject {
        id: sliderBackend

        property real value: 50
        property bool inSync: value === slider.value
        property var changeToValue: undefined

        property Timer timer: Timer {
            interval: 2000

            onTriggered: {
                sliderBackend.value = sliderBackend.changeToValue;
            }
        }
    }

    QtObject {
        id: apBackend

        property bool active: false
        property bool inSync: active === apMenu.active

        property Timer timer: Timer {
            interval: 2000
            onTriggered: apBackend.active = !apBackend.active
        }
    }


    Column {
        anchors.fill: parent
        anchors.margins: units.gu(1)

        spacing: units.gu(2)

        Row {
            spacing: units.gu(3)

            Switch {
                id: switchControl
                anchors.verticalCenter: parent.verticalCenter

                USC.ServerPropertySynchroniser {
                    id: switchSync
                    objectName: "switchSync"

                    syncTimeout: 3000

                    userTarget: switchControl
                    userProperty: "checked"

                    serverTarget: switchBackend
                    serverProperty: "checked"

                    onSyncTriggered: switchBackend.timer.start()
                    onSyncWaitingChanged: switchSyncSpy.clear()
                }
            }

            Column {
                Label { text: switchBackend.inSync ? "synced" : "out of sync" }
                Label { text: switchSync.syncWaiting ? "syncWait" : "no syncWait" }
                Label { text: "activates: " + switchSyncSpy.count }
            }
        }

        Row {
            spacing: units.gu(3)

            CheckBox {
                id: checkControl
                anchors.verticalCenter: parent.verticalCenter

                USC.ServerPropertySynchroniser {
                    id: checkSync
                    objectName: "checkSync"

                    syncTimeout: 3000

                    userTarget: checkControl
                    userProperty: "checked"

                    serverTarget: checkBackend
                    serverProperty: "checked"

                    onSyncTriggered: checkBackend.timer.start()

                    onSyncWaitingChanged: checkSyncSpy.clear()
                }
            }

            Column {
                Label { text: checkBackend.inSync ? "synced" : "out of sync" }
                Label { text: checkSync.syncWaiting ? "syncWait" : "no syncWait" }
                Label { text: "activates: " + checkSyncSpy.count }
            }
        }

        Row {
            id: sliderRoot
            spacing: units.gu(3)

            Slider {
                id: slider
                anchors.verticalCenter: parent.verticalCenter
                live: true
                minimumValue: 0.0
                maximumValue: 100.0

                property real serverValue: sliderBackend.value
                USC.ServerPropertySynchroniser {
                    id: sliderSync
                    objectName: "sliderSync"

                    syncTimeout: 3000
                    maximumWaitBufferInterval: 50

                    userTarget: slider
                    userProperty: "value"

                    serverTarget: slider
                    serverProperty: "serverValue"

                    onSyncTriggered: {
                        sliderBackend.changeToValue = value;
                        sliderBackend.timer.start();
                    }

                    onSyncWaitingChanged: sliderSyncSpy.clear()
                }
            }

            Column {
                Label { text: sliderBackend.inSync ? "synced" : "out of sync" }
                Label { text: sliderSync.syncWaiting ? "syncWait" : "no syncWait" }
                Label { text: "activates: " + sliderSyncSpy.count }
            }
        }

        Row {
            spacing: units.gu(3)
            height: childrenRect.height
            anchors.left: parent.left
            anchors.right: parent.right

            USM.AccessPointMenu {
                id: apMenu
                width: units.gu(30)

                text: "Test Check Menu"

                USC.ServerPropertySynchroniser {
                    id: apMenuSync
                    objectName: "apMenuSync"

                    syncTimeout: 3000

                    userTarget: apMenu
                    userProperty: "active"
                    userTrigger: "onTriggered"

                    serverTarget: apBackend
                    serverProperty: "active"

                    onSyncTriggered: apBackend.timer.start()

                    onSyncWaitingChanged: switchSyncSpy.clear()
                }
            }

            Column {
                Label { text: apBackend.inSync ? "synced" : "out of sync" }
                Label { text: apMenuSync.syncWaiting ? "syncWait" : "no syncWait" }
                Label { text: "activates: " + apSyncSpy.count }
            }
        }
    }

    SignalSpy {
        id: switchSyncSpy
        target: switchControl
        signalName: "triggered"
    }
    SignalSpy {
        id: checkSyncSpy
        target: checkControl
        signalName: "triggered"
    }
    SignalSpy {
        id: sliderSyncSpy
        target: slider
        signalName: "valueChanged"
    }
    SignalSpy {
        id: apSyncSpy
        target: apMenu
        signalName: "triggered"
    }
    SignalSpy {
        id: sliderSyncActivatedSpy
        target: sliderSync
        signalName: "syncTriggered"
    }
    SignalSpy {
        id:apSyncActivatedSpy
        target: apMenuSync
        signalName: "syncTriggered"
    }

    QtObject {
        id: switchBackend2

        property bool checked2: false
        property bool inSync: checked2 === switchControl.checked

        property Timer switchTimer: Timer {
            interval: 1000
            onTriggered: switchBackend2.checked2 = !switchBackend2.checked2
        }
    }

    UbuntuTestCase {
        name: "ServerActivationSync"
        when: windowShown

        function init() {
            waitForRendering(root);

            switchSync.reset();
            checkSync.reset();
            sliderSync.reset();
            apMenuSync.reset();

            switchBackend.timer.interval = 100;
            checkBackend.timer.interval = 100;
            sliderBackend.timer.interval = 200;
            apBackend.timer.interval = 100;

            switchSync.syncTimeout = 200;
            checkSync.syncTimeout = 200;
            sliderSync.syncTimeout = 400;
            apMenuSync.syncTimeout = 200;

            sliderSyncActivatedSpy.clear();
            apSyncActivatedSpy.clear();
        }

        function cleanup() {
            switchBackend.timer.stop();
            checkBackend.timer.stop();
            sliderBackend.timer.stop();

            switchBackend.checked = false;
            checkBackend.checked = false;
            sliderBackend.value = 50;
            apBackend.active = false;

            sliderSync.maximumWaitBufferInterval = -1

            tryCompare(switchBackend, "inSync", true);
            tryCompare(checkBackend, "inSync", true);
            tryCompare(sliderBackend, "inSync", true);

            switchSync.serverTarget = switchBackend;
            switchSync.serverProperty = "checked";
        }

        function test_backend_change() {
            switchBackend.checked = true;
            compare(switchControl.checked, true, "Switch should have been toggled");
            switchBackend.checked = false;
            compare(switchControl.checked, false, "Switch should have been toggled");
        }

        function test_frontend_change() {
            switchControl.trigger();
            tryCompare(switchBackend, "checked", true);
        }

        function test_frontend_change_with_value() {
            slider.value = 60;
            tryCompare(sliderBackend, "value", 60);
        }

        function test_break_binding_change() {
            switchControl.checked = true;
            switchBackend.checked = true;
            switchBackend.checked = false;
            compare(switchControl.checked, false, "Switch should have been toggled");
        }

        function test_buffered_change_with_value() {
            slider.value = 60;
            compare(sliderSyncActivatedSpy.count, 1, "activated signal should have been sent")
            slider.value = 70;
            slider.value = 80;
            slider.value = 90;
            compare(sliderSyncActivatedSpy.count, 1, "activated signals should have been buffered")
            tryCompare(sliderBackend, "value", 90);
            tryCompare(sliderSyncActivatedSpy, "count", 2)
        }

        function test_buffered_change_with_maximum_interval() {
            sliderSync.maximumWaitBufferInterval = 25;
            sliderSync.syncTimeout = 5000;

            slider.value = 60;
            compare(sliderSyncActivatedSpy.count, 1, "activated signal should have been sent");
            slider.value = 70;
            slider.value = 80;
            wait(100); // wait for buffer timeout
            tryCompare(sliderSyncActivatedSpy, "count", 2, 1000, "aditional activate signal should have been sent");
            compare(slider.value, 80, "value should be set to last activate");

            slider.value = 90;
            wait(100); // wait for buffer timeout
            tryCompare(sliderSyncActivatedSpy, "count", 3, 1000, "aditional activate signal should have been sent");
            compare(slider.value, 90, "value should be set to last activate");
        }

        function test_connect_to_another_object() {
            switchSync.serverTarget = switchBackend2;
            switchSync.serverProperty = "checked2";

            switchBackend2.checked2 = true;
            compare(switchControl.checked, true, "Switch should have been toggled");
            switchBackend2.checked2 = false;
            compare(switchControl.checked, false, "Switch should have been toggled");
        }

        function test_client_revert() {
            switchBackend.timer.interval = 500;
            switchControl.trigger();
            compare(switchControl.checked, true);
            tryCompare(switchControl, "checked", false);
        }

        function test_user_trigger() {
            apMenu.trigger();

            compare(apSyncActivatedSpy.count, 1, "Triggering should have caused signal to be emitted");
            tryCompare(apBackend, "active", true);
            compare(apMenu.active, true, "User value should have updated to match server");
        }

        function test_user_trigger_doesnt_activate_on_user_property_change() {
            apMenu.active = true;
            compare(apSyncActivatedSpy.count, 0);
        }
    }
}
