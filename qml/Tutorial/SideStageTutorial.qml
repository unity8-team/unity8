/*
 * Copyright (C) 2016 Canonical, Ltd.
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

    property bool paused: false
    readonly property alias running: d.running

    Component.onCompleted: {
        d.start();
    }

    signal finished()

    function finish() {
        d.stop();
        finished();
    }

    QtObject {
        id: d

        property bool running

        function stop() {
            running = false;
        }

        function start() {
            running = true;
            tutorialSideStage.show();
        }
    }

    SideStageTutorialPage {
        id: tutorialSideStage
        objectName: "tutorialSideStage"
        backgroundFadesIn: true
        backgroundFadesOut: true
        anchors.fill: parent
        paused: !shown || root.paused
        panel: root.panel

        onFinished: root.finish()
    }
}
