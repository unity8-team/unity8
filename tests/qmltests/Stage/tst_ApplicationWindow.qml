/*
 * Copyright 2014-2017 Canonical Ltd.
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
import QtTest 1.0
import Unity.Test 0.1 as UT
import ".."
import "../../../qml/Stage"
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Unity.Application 0.1

Rectangle {
    color: "red"
    id: root
    width: units.gu(70)
    height: units.gu(70)

    readonly property QtObject fakeApplication: applicationWindowLoader.item ? applicationWindowLoader.item.application : null

    SurfaceManager{}

    Loader {
        id: applicationWindowLoader
        focus: true
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }
        width: units.gu(40)
        property bool itemDestroyed: false
        sourceComponent: Component {
            ApplicationWindow {
                anchors.fill: parent
                surfaceOrientationAngle: 0
                interactive: true
                focus: true
                requestedWidth: width
                requestedHeight: height
                Component.onDestruction: {
                    applicationWindowLoader.itemDestroyed = true;
                }
                Component.onCompleted: {
                    MirTest.manualSurfaceCreation = true;
                    application = ApplicationManager.startApplication("gallery-app");
                }
            }
        }
    }

    Rectangle {
        color: "white"
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: applicationWindowLoader.right
            right: parent.right
        }

        ColumnLayout {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: units.gu(1) }
            spacing: units.gu(1)

            RowLayout {
                Layout.fillWidth: true

                CheckBox {
                    id: surfaceCheckbox
                    checked: false;
                    activeFocusOnPress: false
                    enabled: root.fakeApplication !== null
                    onCheckedChanged: {
                        if (applicationWindowLoader.status !== Loader.Ready)
                            return;

                        if (checked) {
                            testCase.createSurface();
                        } else {
                            if (applicationWindowLoader.item.surface) {
                                MirTest.killSurface(root.fakeApplication.appId, applicationWindowLoader.item.surface);
                            }
                        }
                    }
                }
                Label {
                    text: "Surface"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            RowLayout {
                property var promptSurfaceList: root.fakeApplication ? root.fakeApplication.promptSurfaceList : null
                Button {
                    enabled: root.fakeApplication && root.fakeApplication.promptSurfaceList.count > 0
                    activeFocusOnPress: false
                    text: "Remove"
                    onClicked: { root.fakeApplication.promptSurfaceList.get(0).close(); }
                }

                Button {
                    enabled: root.fakeApplication
                    activeFocusOnPress: false
                    text: "Add Prompt Surface"
                    onClicked: { MirTest.createPromptSurface(root.fakeApplication.appId); }
                }
            }

            Label {
                text: "Application state: " + applicationStateStr
                function stateToStr(state) {
                    if (state == ApplicationInfoInterface.Starting) {
                        return "Starting";
                    } else if (state == ApplicationInfoInterface.Running) {
                        return "Running";
                    } else if (state == ApplicationInfoInterface.Suspended) {
                        return "Suspended";
                    } else {
                        return "Stopped";
                    }
                }
                readonly property string applicationStateStr: root.fakeApplication ? stateToStr(root.fakeApplication.state) : "null"
            }


            Button {
                activeFocusOnPress: false
                enabled: root.fakeApplication === null ||
                    (root.fakeApplication.state === ApplicationInfoInterface.Running
                     || root.fakeApplication.state === ApplicationInfoInterface.Suspended)
                text: {
                    if (root.fakeApplication !== null) {
                        if (root.fakeApplication.requestedState === ApplicationInfoInterface.RequestedSuspended) {
                            return "Resume";
                        } else if (root.fakeApplication.requestedState = ApplicationInfoInterface.RequestedRunning) {
                            return "Suspend";
                        }
                    } else {
                        return "Start";
                    }
                }
                onClicked: {
                    if (text === "Suspend") {
                        root.fakeApplication.requestedState = ApplicationInfoInterface.RequestedSuspended;
                    } else if (text === "Resume") {
                        root.fakeApplication.requestedState = ApplicationInfoInterface.RequestedRunning;
                    } else if (text === "Start") {
                        applicationWindowLoader.item.application = ApplicationManager.startApplication("gallery-app");
                    }
                }
            }
        }
    }

    UT.UnityTestCase {
        id: testCase
        name: "ApplicationWindow"
        when: windowShown

        property var applicationWindow: applicationWindowLoader.item

        // holds some of the internal ApplicationWindow objects we probe during the tests
        property var stateGroup: null

        function createSurface() {
            var application = applicationWindowLoader.item.application;
            MirTest.createSurface(application.appId);
            while (application.surfaceList.count == 0) {
                testCase.wait(50);
            }
            applicationWindowLoader.item.surface = application.surfaceList.get(0);
        }

        function findInterestingApplicationWindowChildren() {
            stateGroup = findInvisibleChild(applicationWindowLoader.item, "applicationWindowStateGroup");
            verify(stateGroup);
        }

        function forgetApplicationWindowChildren() {
            stateGroup = null;
        }

        function init() {
            applicationWindowLoader.active = true;
            tryCompare(applicationWindowLoader, "status", Loader.Ready);
            tryCompareFunction(function() { return root.fakeApplication !== null; }, true);
            tryCompareFunction(function(){ return MirTest.internalState(root.fakeApplication); }, MirTest.StartingWithSession);

            findInterestingApplicationWindowChildren();
        }

        function cleanup() {
            forgetApplicationWindowChildren();

            applicationWindowLoader.itemDestroyed = false;

            // reload our test subject to get it in a fresh state once again
            applicationWindowLoader.active = false;

            tryCompare(applicationWindowLoader, "status", Loader.Null);
            tryCompare(applicationWindowLoader, "item", null);
            // Loader.status might be Loader.Null and Loader.item might be null but the Loader
            // item might still be alive. So if we set Loader.active back to true
            // again right now we will get the very same ApplicationWindow instance back. So no reload
            // actually took place. Likely because Loader waits until the next event loop
            // iteration to do its work. So to ensure the reload, we will wait until the
            // ApplicationWindow instance gets destroyed.
            // Another thing that happens is that we do get a new object but the old one doesn't get
            // deleted, so you end up with two instances in memory.
            tryCompare(applicationWindowLoader, "itemDestroyed", true);

            killApps();
        }

        function waitUntilSurfaceContainerStopsAnimating(container) {
            var animationsLoader = findChild(container, "animationsLoader");
            verify(animationsLoader);
            tryCompare(animationsLoader, "status", Loader.Ready)

            var animation = animationsLoader.item;
            waitUntilTransitionsEnd(animation);
        }

        function suspend() {
            root.fakeApplication.requestedState = ApplicationInfoInterface.RequestedSuspended;
            tryCompareFunction(function(){ return MirTest.internalState(root.fakeApplication); }, MirTest.Suspended);
        }

        function test_showSplashUntilAppFullyInit() {
            verify(stateGroup.state === "splashScreen");

            createSurface();

            tryCompare(stateGroup, "state", "surface");
        }

        function test_suspendedAppShowsSurface() {
            createSurface();
            tryCompare(root.fakeApplication, "state", ApplicationInfoInterface.Running);
            tryCompare(stateGroup, "state", "surface");

            waitUntilTransitionsEnd(stateGroup);

            suspend();

            verify(stateGroup.state === "surface");
            waitUntilTransitionsEnd(stateGroup);
        }

        function test_killedAppShowsScreenshot() {
            createSurface();
            tryCompare(root.fakeApplication, "state", ApplicationInfoInterface.Running);
            tryCompare(stateGroup, "state", "surface");

            suspend();

            verify(stateGroup.state === "surface");
            verify(fakeApplication.surfaceList.count, 1);

            // kill it!
            MirTest.killApplication(root.fakeApplication.appId);
            tryCompareFunction(function(){ return MirTest.internalState(root.fakeApplication); }, MirTest.StoppedResumable);
            tryCompare(applicationWindow, "surface", null);

            tryCompare(stateGroup, "state", "screenshot");
        }

        function test_restartApp() {
            var screenshotImage = findChild(applicationWindow, "screenshotImage");

            createSurface();
            tryCompare(root.fakeApplication, "state", ApplicationInfoInterface.Running);
            tryCompare(stateGroup, "state", "surface");
            waitUntilTransitionsEnd(stateGroup);

            suspend();

            // kill it
            MirTest.killApplication(root.fakeApplication.appId);
            tryCompareFunction(function(){ return MirTest.internalState(root.fakeApplication); }, MirTest.StoppedResumable);

            tryCompare(stateGroup, "state", "screenshot");
            waitUntilTransitionsEnd(stateGroup);
            tryCompare(applicationWindow, "surface", null);

            // and restart it
            root.fakeApplication.requestedState = ApplicationInfoInterface.RequestedRunning;
            tryCompareFunction(function(){ return MirTest.internalState(root.fakeApplication); }, MirTest.StartingWithSession);

            waitUntilTransitionsEnd(stateGroup);
            verify(stateGroup.state === "screenshot");
            verify(applicationWindow.surface === null);

            createSurface();

            tryCompare(stateGroup, "state", "surface");
            tryCompare(screenshotImage, "status", Image.Null);
        }

        function test_appCrashed() {
            createSurface();
            tryCompare(root.fakeApplication, "state", ApplicationInfoInterface.Running);
            tryCompare(stateGroup, "state", "surface");
            waitUntilTransitionsEnd(stateGroup);

            // oh, it crashed...
            MirTest.killApplication(root.fakeApplication.appId);
            tryCompare(root, "fakeApplication", null);

            tryCompare(stateGroup, "state", "screenshot");
            tryCompare(applicationWindow, "surface", null);
        }

        function test_keepSurfaceWhileInvisible() {
            createSurface();
            tryCompare(root.fakeApplication, "state", ApplicationInfoInterface.Running);
            tryCompare(stateGroup, "state", "surface");
            waitUntilTransitionsEnd(stateGroup);
            verify(applicationWindow.surface !== null);

            applicationWindow.visible = false;

            waitUntilTransitionsEnd(stateGroup);
            verify(stateGroup.state === "surface");
            verify(applicationWindow.surface !== null);

            applicationWindow.visible = true;

            waitUntilTransitionsEnd(stateGroup);
            verify(stateGroup.state === "surface");
            verify(applicationWindow.surface !== null);
        }

        function test_touchesReachSurfaceWhenItsShown() {
            createSurface();
            tryCompare(root.fakeApplication, "state", ApplicationInfoInterface.Running);

            tryCompare(stateGroup, "state", "surface");

            waitUntilTransitionsEnd(stateGroup);

            var surfaceItem = findChild(applicationWindow, "surfaceItem");
            verify(surfaceItem);
            verify(surfaceItem.surface === applicationWindow.surface);

            tap(applicationWindow);

            tryCompareFunction(function(){ return MirTest.touchPressCount(applicationWindow.surface); }, 1);
            tryCompareFunction(function(){ return MirTest.touchReleaseCount(applicationWindow.surface); }, 1);
        }

        function test_showNothingOnSuddenSurfaceLoss() {
            createSurface();
            tryCompare(root.fakeApplication, "state", ApplicationInfoInterface.Running);
            tryCompare(stateGroup, "state", "surface");
            waitUntilTransitionsEnd(stateGroup);

            applicationWindow.surface = null;

            tryCompare(stateGroup, "state", "void");
        }

        function test_promptSurfaceDestructionReturnsFocusToPreviousSurface() {
            skip("No support for nested prompt sessions yet when using internal mir clients. Will work once prompts are per-surface and not per-pid");
            createSurface();
            tryCompare(root.fakeApplication, "state", ApplicationInfoInterface.Running);

            var promptSurfaces = testCase.findChild(applicationWindow, "promptSurfacesRepeater");
            var promptSurfaceList = root.fakeApplication.promptSurfaceList;
            compare(promptSurfaces.count, 0);

            var i;
            // 3 surfaces should cover all edge cases
            for (i = 0; i < 3; i++) {
                MirTest.createPromptSurface(root.fakeApplication.appId);
                tryCompare(promptSurfaces, "count", i+1);
                waitUntilSurfaceContainerStopsAnimating(promptSurfaces.itemAt(0));
            }

            for (i = 3; i > 0; --i) {
                var promptSurface = promptSurfaceList.get(0);
                tryCompare(promptSurface, "activeFocus", true);

                promptSurface.close();
                promptSurface = null;
                tryCompareFunction(function() { return promptSurfaces.count; }, i-1);

                if (promptSurfaces.count > 0) {
                    // active focus should have gone to the new head of the list
                    promptSurface = promptSurfaceList.get(0);
                    tryCompare(promptSurface, "activeFocus", true);
                } else {
                    // active focus should have gone to the application surface
                    tryCompare(applicationWindow.surface, "activeFocus", true);
                }
            }
        }

        function test_promptSurfaceAdjustsForParentSize() {
            MirTest.createPromptSurface(root.fakeApplication.appId);

            var promptSurfaces = testCase.findChild(applicationWindow, "promptSurfacesRepeater");

            tryCompare(promptSurfaces, "count", 1);
            var delegate = promptSurfaces.itemAt(0);
            waitUntilSurfaceContainerStopsAnimating(delegate);

            var promptSurfaceContainer = findChild(delegate, "surfaceContainer");

            tryCompareFunction(function() { return promptSurfaceContainer.height === applicationWindow.height; }, true);
            tryCompareFunction(function() { return promptSurfaceContainer.width === applicationWindow.width; }, true);
            tryCompareFunction(function() { return promptSurfaceContainer.x === 0; }, true);
            tryCompareFunction(function() { return promptSurfaceContainer.y === 0; }, true);

            applicationWindow.anchors.margins = units.gu(2);

            tryCompareFunction(function() { return promptSurfaceContainer.height === applicationWindow.height; }, true);
            tryCompareFunction(function() { return promptSurfaceContainer.width === applicationWindow.width; }, true);
            tryCompareFunction(function() { return promptSurfaceContainer.x === 0; }, true);
            tryCompareFunction(function() { return promptSurfaceContainer.y === 0; }, true);
        }

        // Check that the z value of SurfaceContainers for prompt surfaces go from highest
        // for index 0 to lowest for the last index in the prompt surface list.
        // Regression test for https://bugs.launchpad.net/bugs/1586219
        function test_promptSurfacesZOrdering() {
            skip("No support for nested prompt sessions yet when using internal mir clients. Will work once prompts are per-surface and not per-pid");

            var promptSurfaceList = root.fakeApplication.promptSurfaceList;
            var promptSurfaces = testCase.findChild(applicationWindow, "promptSurfacesRepeater");

            MirTest.createPromptSurface(root.fakeApplication.appId);

            for (var i = 2; i <= 3; i++) {
                MirTest.createPromptSurface(root.fakeApplication.appId);
                tryCompare(promptSurfaces, "count", i);
                waitUntilSurfaceContainerStopsAnimating(promptSurfaces.itemAt(0));

                for (var j = 1; j < promptSurfaces.count; j++) {
                    var delegate = promptSurfaces.itemAt(j);
                    var previousDelegate = promptSurfaces.itemAt(j-1);
                    verify(previousDelegate.z > delegate.z);
                }
            }

            // clean up
            while (promptSurfaceList.count > 0) {
                var currentCount = promptSurfaceList.count;
                promptSurfaceList.get(0).close();
                tryCompare(promptSurfaceList, "count", currentCount - 1);
            }
        }
    }
}
