/*
 * Copyright 2014 Canonical Ltd.
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

import QtQuick 2.3
import QtTest 1.0
import Ubuntu.Test 0.1
import Ubuntu.Settings.Components 0.1 as USC
import Ubuntu.Components 0.1

Item {
    id: root
    width: units.gu(60)
    height: units.gu(70)

    QtObject {
        id: switchBackend

        property bool checked: false
        property bool inSync: checked === switchControl.checked

        property Timer switchTimer: Timer {
            interval: 1000
            onTriggered: switchBackend.checked = !switchBackend.checked
        }
    }

    QtObject {
        id: checkBackend

        property bool checked: false
        property bool inSync: checked === checkControl.checked

        property Timer checkTimer: Timer {
            interval: 1000
            onTriggered: checkBackend.checked = !checkBackend.checked
        }
    }

    QtObject {
        id: sliderBackend

        property real value: 50
        property bool inSync: value === slider.value

        property Timer sliderTimer: Timer {
            interval: 1000

            property var changeToValue: undefined
            onTriggered: {
                sliderBackend.value = changeToValue;
            }
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

                onTriggered: switchSync.activate()

                USC.ServerActivationSync {
                    id: switchSync
                    syncTimeout: 2000

                    userTarget: switchControl
                    userProperty: "checked"

                    serverTarget: switchBackend
                    serverProperty: "checked"

                    onActivated: switchBackend.switchTimer.start()

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

                onTriggered: checkSync.activate()

                USC.ServerActivationSync {
                    id: checkSync

                    syncTimeout: 2000

                    userTarget: checkControl
                    userProperty: "checked"

                    serverTarget: checkBackend
                    serverProperty: "checked"

                    onActivated: checkBackend.checkTimer.start()

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

                onValueChanged: sliderSync.activate()

                USC.ServerActivationSync {
                    id: sliderSync

                    syncTimeout: 2000

                    userTarget: slider
                    userProperty: "value"

                    serverTarget: sliderBackend
                    serverProperty: "value"

                    onActivated: {
                        sliderBackend.sliderTimer.changeToValue = value;
                        sliderBackend.sliderTimer.start();
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
        id: sliderSyncActivatedSpy
        target: sliderSync
        signalName: "activated"
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
            switchBackend.switchTimer.interval = 100;
            checkBackend.checkTimer.interval = 100;
            sliderBackend.sliderTimer.interval = 100;

            switchSync.syncTimeout = 200;
            checkSync.syncTimeout = 200;
            sliderSync.syncTimeout = 200;
            sliderSyncActivatedSpy.clear();
        }

        function cleanup() {
            switchBackend.checked = false;
            checkBackend.checked = false;
            sliderBackend.value = 50;

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
            switchControl.clicked();
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
            tryCompare(sliderSyncActivatedSpy, "count", 2)
            tryCompare(sliderBackend, "value", 90);
        }

        function test_connect_to_another_object() {
            switchSync.serverTarget = switchBackend2;
            switchSync.serverProperty = "checked2";

            switchBackend2.checked2 = true;
            compare(switchControl.checked, true, "Switch should have been toggled");
            switchBackend2.checked2 = false;
            compare(switchControl.checked, false, "Switch should have been toggled");
        }
    }
}
