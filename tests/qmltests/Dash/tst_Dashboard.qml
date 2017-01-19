/*
 * Copyright (C) 2013-2016 Canonical, Ltd.
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
import AccountsService 0.1
import GSettings 1.0
import LightDM.IntegratedLightDM 0.1 as LightDM
import SessionBroadcast 0.1
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Unity.Application 0.1
import Unity.ApplicationMenu 0.1
import Unity.Indicators 0.1
import Unity.Launcher 0.1
import Unity.Test 0.1
import Powerd 0.1
import Wizard 0.1 as Wizard
import Utils 0.1
import Unity.Indicators 0.1 as Indicators

import "../../../qml"
import "../../../qml/Components"
import "../../../qml/Components/PanelState"
import "../Stage"
import ".."

Rectangle {
    id: root
    color: "grey"
    width: units.gu(100) + controls.width
    height: units.gu(71)

    Component.onCompleted: {
        // must set the mock mode before loading the Shell
        LightDM.Greeter.mockMode = "single";
        LightDM.Users.mockMode = "single";
        shellLoader.active = true;
    }

    ApplicationMenuDataLoader {
        id: appMenuData
    }

    property var shell: shellLoader.item ? shellLoader.item : null
    onShellChanged: {
        if (shell) {
            topLevelSurfaceList = testCase.findInvisibleChild(shell, "topLevelSurfaceList");
            appMenuData.surfaceManager = testCase.findInvisibleChild(shell, "surfaceManager");
            dashboard = testCase.findChild(shell, "dashboard");
        } else {
            topLevelSurfaceList = null;
            appMenuData.surfaceManager = null;
            dashboard = null;
        }
    }

    property var topLevelSurfaceList: null
    property var dashboard: null

    Item {
        id: shellContainer
        anchors.left: root.left
        anchors.right: controls.left
        anchors.top: root.top
        anchors.bottom: root.bottom
        Loader {
            id: shellLoader
            focus: true

            anchors.centerIn: parent

            property int shellOrientation: Qt.PortraitOrientation
            property int nativeOrientation: Qt.PortraitOrientation
            property int primaryOrientation: Qt.PortraitOrientation
            property string mode: "shell"

            state: "phone"
            states: [
                State {
                    name: "phone"
                    PropertyChanges {
                        target: shellLoader
                        width: units.gu(40)
                        height: units.gu(71)
                    }
                },
                State {
                    name: "tablet"
                    PropertyChanges {
                        target: shellLoader
                        width: units.gu(100)
                        height: units.gu(71)
                        shellOrientation: Qt.LandscapeOrientation
                        nativeOrientation: Qt.LandscapeOrientation
                        primaryOrientation: Qt.LandscapeOrientation
                    }
                },
                State {
                    name: "desktop"
                    PropertyChanges {
                        target: shellLoader
                        width: shellContainer.width
                        height: shellContainer.height
                    }
                    PropertyChanges {
                        target: mouseEmulation
                        checked: false
                    }
                }
            ]

            active: false
            property bool itemDestroyed: false
            sourceComponent: Component {
                Shell {
                    id: __shell
                    objectName: "shell"
                    usageScenario: usageScenarioSelector.model[usageScenarioSelector.selectedIndex]
                    onUsageScenarioChanged: columnCountSelector.selectedIndex = usageScenarioSelector.selectedIndex;
                    nativeWidth: width
                    nativeHeight: height
                    orientation: shellLoader.shellOrientation
                    orientations: Orientations {
                        native_: shellLoader.nativeOrientation
                        primary: shellLoader.primaryOrientation
                    }
                    mode: "shell"

                    Component.onDestruction: {
                        shellLoader.itemDestroyed = true;
                    }
                }
            }
        }
    }

    Flickable {
        id: controls
        contentHeight: controlRect.height

        anchors.top: root.top
        anchors.bottom: root.bottom
        anchors.right: root.right
        width: units.gu(30)

        Rectangle {
            id: controlRect
            anchors { left: parent.left; right: parent.right }
            color: "darkgrey"
            height: childrenRect.height + units.gu(2)

            Column {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: units.gu(1) }
                spacing: units.gu(1)

                Flow {
                    spacing: units.gu(1)
                    anchors { left: parent.left; right: parent.right }

                    Button {
                        text: "Show Launcher"
                        activeFocusOnPress: false
                        enabled: !autohideLauncherCheckbox.checked
                        onClicked: {
                            if (shellLoader.status !== Loader.Ready)
                                return;

                            var launcher = testCase.findChild(shell, "launcher");
                            launcher.state = "visible";
                        }
                    }
                    Button {
                        text: "Print focused"
                        activeFocusOnPress: false
                        onClicked: {
                            var childs = [];
                            childs.push(shell)
                            while (childs.length > 0) {
                                if (childs[0].activeFocus && childs[0].focus && childs[0].objectName != "shell") {
                                    console.log("Active focus is on item:", childs[0]);
                                    return;
                                }
                                for (var i in childs[0].children) {
                                    childs.push(childs[0].children[i])
                                }
                                childs.splice(0, 1);
                            }
                            console.log("No active focused item found within shell.")
                        }
                    }
                }

                ListItem.ItemSelector {
                    id: columnCountSelector
                    anchors { left: parent.left; right: parent.right }
                    activeFocusOnPress: false
                    text: "Dashboard column count"
                    model: [1, 3, 5]
                    onSelectedIndexChanged: {
                        if (dashboard) dashboard.columnCount = model[selectedIndex];
                    }
                }

                ListItem.ItemSelector {
                    id: sizeSelector
                    anchors { left: parent.left; right: parent.right }
                    activeFocusOnPress: false
                    text: "Size"
                    model: ["phone", "tablet", "desktop"]
                    selectedIndex: 2
                    onSelectedIndexChanged: {
                        shellLoader.state = model[selectedIndex];
                    }
                }

                ListItem.ItemSelector {
                    id: usageScenarioSelector
                    anchors { left: parent.left; right: parent.right }
                    activeFocusOnPress: false
                    text: "Usage scenario"
                    selectedIndex: 2
                    model: ["phone", "tablet", "desktop"]
                }

                MouseTouchEmulationCheckbox {
                    id: mouseEmulation
                    checked: true
                }

                ListItem.ItemSelector {
                    id: ctrlModifier
                    anchors { left: parent.left; right: parent.right }
                    activeFocusOnPress: false
                    text: "Ctrl key as"
                    model: ["Ctrl", "Alt", "Super"]
                    onSelectedIndexChanged: {
                        var keyMapper = testCase.findChild(shellContainer, "physicalKeysMapper");
                        keyMapper.controlInsteadOfAlt = selectedIndex == 1;
                        keyMapper.controlInsteadOfSuper = selectedIndex == 2;
                    }
                }

                Row {
                    anchors { left: parent.left; right: parent.right }
                    CheckBox {
                        id: autohideLauncherCheckbox
                        activeFocusOnPress: false
                        onCheckedChanged:  {
                            GSettingsController.setAutohideLauncher(checked)
                        }
                    }
                    Label {
                        text: "Autohide launcher"
                    }
                }
            }
        }
    }

    SignalSpy {
        id: launcherShowDashHomeSpy
        signalName: "showDashHome"
    }

    SignalSpy {
        id: sessionSpy
        signalName: "sessionStarted"
    }

    SignalSpy {
        id: dashCommunicatorSpy
        signalName: "setCurrentScopeCalled"
    }

    SignalSpy {
        id: broadcastUrlSpy
        target: SessionBroadcast
        signalName: "startUrl"
    }

    SignalSpy {
        id: broadcastHomeSpy
        target: SessionBroadcast
        signalName: "showHome"
    }

    Item {
        id: fakeDismissTimer
        property bool running: false
        signal triggered

        function stop() {
            running = false;
        }

        function restart() {
            running = true;
        }
    }

    StageTestCase {
        id: testCase
        name: "Shell"
        when: windowShown

        property Item shell: shellLoader.status === Loader.Ready ? shellLoader.item : null

        function init() {
            if (shellLoader.active) {
                // happens for the very first test function as shell
                // is loaded by default
                tearDown();
            }
        }

        function cleanup() {
            waitForRendering(shell);
            mouseEmulation.checked = true;
            tryCompare(shell, "waitingOnGreeter", false); // make sure greeter didn't leave us in disabled state
            tearDown();
            WindowStateStorage.clear();
        }

        function loadShell(formFactor) {
            shellLoader.state = formFactor;
            shellLoader.active = true;
            tryCompare(shellLoader, "status", Loader.Ready);
            removeTimeConstraintsFromSwipeAreas(shellLoader.item);
            tryCompare(shell, "waitingOnGreeter", false); // reset by greeter when ready

            sessionSpy.target = findChild(shell, "greeter")
            dashCommunicatorSpy.target = findInvisibleChild(shell, "dashCommunicator");

            var launcher = findChild(shell, "launcher");
            launcherShowDashHomeSpy.target = launcher;

            var panel = findChild(launcher, "launcherPanel");
            verify(!!panel);

            panel.dismissTimer = fakeDismissTimer;

            waitForGreeterToStabilize();

            // from StageTestCase
            topLevelSurfaceList = findInvisibleChild(shell, "topLevelSurfaceList");
            verify(topLevelSurfaceList);
            stage = findChild(shell, "stage");
        }

        function waitForGreeterToStabilize() {
            var greeter = findChild(shell, "greeter");
            verify(greeter);

            var loginList = findChild(greeter, "loginList", 0 /* timeout */);
            // Only present in WideView
            if (loginList) {
                var userList = findChild(loginList, "userList");
                verify(userList);
                tryCompare(userList, "movingInternally", false);
            }
        }

        function tearDown() {
            launcherShowDashHomeSpy.target = null;

            shellLoader.itemDestroyed = false;

            shellLoader.active = false;

            tryCompare(shellLoader, "status", Loader.Null);
            tryCompare(shellLoader, "item", null);
            // Loader.status might be Loader.Null and Loader.item might be null but the Loader
            // item might still be alive. So if we set Loader.active back to true
            // again right now we will get the very same Shell instance back. So no reload
            // actually took place. Likely because Loader waits until the next event loop
            // iteration to do its work. So to ensure the reload, we will wait until the
            // Shell instance gets destroyed.
            tryCompare(shellLoader, "itemDestroyed", true);

            setLightDMMockMode("single"); // back to the default value

            AccountsService.demoEdges = false;
            AccountsService.demoEdgesCompleted = [];
            AccountsService.backgroundFile = "";
            Wizard.System.wizardEnabled = false;
            shellLoader.mode = "shell";

            // kill all (fake) running apps
            killApps();

            LightDM.Greeter.authenticate(""); // reset greeter

            sessionSpy.clear();
            broadcastUrlSpy.clear();
            broadcastHomeSpy.clear();

            GSettingsController.setLifecycleExemptAppids([]);
            GSettingsController.setPictureUri("");
        }

        function setLightDMMockMode(mode) {
            LightDM.Greeter.mockMode = mode;
            LightDM.Users.mockMode = mode;
        }

        function showGreeter() {
            var greeter = findChild(shell, "greeter");
            LightDM.Greeter.showGreeter();
            waitForRendering(greeter);
            tryCompare(greeter, "fullyShown", true);

            // greeter unloads its internal components when hidden
            // and reloads them when shown. Thus we have to do this
            // again before interacting with it otherwise any
            // SwipeAreas in there won't be easily fooled by
            // fake swipes.
            removeTimeConstraintsFromSwipeAreas(greeter);
        }
    }
}
