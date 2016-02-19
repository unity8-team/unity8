/*
 * Copyright (C) 2015-2016 Canonical, Ltd.
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
import Ubuntu.Components 1.3
import GSettings 1.0
import GlobalShortcut 1.0
import QMenuModel 0.1 as QMenuModel
import AccountsService 0.1

Rectangle {
    id: root

    color: "#111111"

    // Controls to be set from outside
    property bool altTabPressed
    property url background
    property bool beingResized
    property int dragAreaWidth
    property bool interactive
    property real inverseProgress // This is the progress for left edge drags, in pixels.
    property bool keepDashRunning: true
    property real maximizedAppTopMargin
    property real nativeHeight
    property real nativeWidth
    property QtObject orientations
    property int shellOrientation
    property int shellOrientationAngle
    property bool spreadEnabled: true // If false, animations and right edge will be disabled
    property bool suspended

    // To be read from outside
    property var mainApp: null
    property var mainAppWindow: null
    property int mainAppWindowOrientationAngle
    property bool orientationChangesEnabled
    property int supportedOrientations: Qt.PortraitOrientation
                                      | Qt.LandscapeOrientation
                                      | Qt.InvertedPortraitOrientation
                                      | Qt.InvertedLandscapeOrientation

    // Shared code for use in stage implementations
    GSettings {
        id: lifecycleExceptions
        schema.id: "com.canonical.qtmir"
    }

    function isExemptFromLifecycle(appId) {
        var shortAppId = appId.split('_')[0];
        for (var i = 0; i < lifecycleExceptions.lifecycleExemptAppids.length; i++) {
            if (shortAppId === lifecycleExceptions.lifecycleExemptAppids[i]) {
                return true;
            }
        }
        return false;
    }

    // keymap switching, shared between stages
    // TODO Work around http://pad.lv/1293478 until qmenumodel knows to cast
    readonly property int stepUp: -1
    readonly property int stepDown: 1

    GlobalShortcut {
        shortcut: Qt.MetaModifier|Qt.Key_Space
        onTriggered: keymapActionGroup.nextAction.activate(stepUp);
    }

    GlobalShortcut {
        shortcut: Qt.MetaModifier|Qt.ShiftModifier|Qt.Key_Space
        onTriggered: keymapActionGroup.nextAction.activate(stepDown);
    }

    QMenuModel.QDBusActionGroup {
        id: keymapActionGroup
        busType: QMenuModel.DBus.SessionBus
        busName: "com.canonical.indicator.keyboard"
        objectPath: "/com/canonical/indicator/keyboard"

        property variant activeAction: action("active")
        property variant currentAction: action("current")
        property variant nextAction: action("scroll")

        Component.onCompleted: {
            keymapActionGroup.start();
            currentAction.updateState(0); // start with first keymap
        }
    }

    // switching
    property int currentKeymapIndex: 0
    readonly property int currentIndicatorIndex: keymapActionGroup.currentAction ? keymapActionGroup.currentAction.state : 0
    onCurrentIndicatorIndexChanged: { // switch the keymap
        if (mainAppWindow) {
            currentKeymapIndex = currentIndicatorIndex;
            mainAppWindow.switchToKeymap(currentIndicatorIndex);
        }
    }

    onMainAppWindowChanged: {
        if (mainAppWindow) {
            mainAppWindow.switchToKeymap(currentKeymapIndex);
        }
    }

    // reading the active keymap
    function updateActiveKeymap() {
        var activeIndex = AccountsService.keymaps.indexOf(activeKeymap);
        if (activeIndex !== -1) {
            // tell the keyboard indicator about the active keymap
            keymapActionGroup.activeAction.updateState(activeIndex);
        }
    }

    readonly property string activeKeymap: mainAppWindow ? mainAppWindow.activeKeymap : "us"
    onActiveKeymapChanged: updateActiveKeymap()
}
