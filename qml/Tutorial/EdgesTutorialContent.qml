/*
 * Copyright (C) 2013,2014 Canonical, Ltd.
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

Item {
    id: root

    property Item launcher
    property Item panel
    property string usageScenario

    readonly property bool launcherEnabled: !running ||
                                            (!paused && tutorialLeft.shown)
    readonly property bool spreadEnabled: !running
    readonly property bool panelEnabled: !running
    readonly property bool panelContentEnabled: !running
    readonly property alias running: d.running

    property bool paused: false
    property real edgeSize

    signal finished()

    function finish() {
        d.stop();
        finished();
    }

    ////

    Component.onCompleted: {
        d.start();
    }

    QtObject {
        id: d

        property bool running

        function stop() {
            running = false;
        }

        function start() {
            running = true;
            tutorialLeft.show();
        }
    }

    LeftEdgeTutorialPage {
        id: tutorialLeft
        objectName: "tutorialLeft"
        anchors.fill: parent
        launcher: root.launcher
        paused: !shown || root.paused

        onFinished: tutorialLeftFinish.show()
    }

    LeftEdgeFinishTutorialPage {
        id: tutorialLeftFinish
        objectName: "tutorialLeftFinish"
        anchors.fill: parent
        textXOffset: root.launcher.panelWidth
        paused: !shown || root.paused
        text: i18n.tr("Tap here to continue.")

        onFinished: {
            root.launcher.hide();
            tutorialRight.show();
        }
    }

    RightEdgeTutorialPage {
        id: tutorialRight
        objectName: "tutorialRight"
        anchors.fill: parent
        edgeSize: root.edgeSize
        panel: root.panel
        paused: !shown || root.paused

        onFinished: tutorialBottom.show()
    }

    BottomEdgeTutorialPage {
        id: tutorialBottom
        objectName: "tutorialBottom"
        anchors.fill: parent
        edgeSize: root.edgeSize
        paused: !shown || root.paused

        onFinished: tutorialBottomFinish.show()
    }

    BottomEdgeFinishTutorialPage {
        id: tutorialBottomFinish
        objectName: "tutorialBottomFinish"
        anchors.fill: parent
        backgroundFadesOut: usageScenario !== "tablet"
        paused: !shown || root.paused

        onFinished: root.finish()
    }
}
