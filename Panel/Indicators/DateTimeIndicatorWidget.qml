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
 * Authors:
 *      Nick Dedekind <nick.dedekind@canonical.com>
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
import Unity.Indicators 0.1 as Indicators

Indicators.IndicatorWidget {
    width: clockLabel.width

    property string rightLabel

    onRightLabelChanged: if (rightLabel != "") clockLabel.currentDate = new Date()

    Label {
        id: clockLabel
        width: guRoundUp(implicitWidth)
        objectName: "clockLabel"
        color: Theme.palette.selected.backgroundText
        opacity: 0.8
        font.family: "Ubuntu"
        fontSize: "medium"
        anchors.verticalCenter: parent.verticalCenter
        visible: text != ""
        text: Qt.formatTime(currentDate)

        property var currentDate: new Date()
    }

    // TODO: Use toolkit function https://bugs.launchpad.net/ubuntu-ui-toolkit/+bug/1242575
    function guRoundUp(width) {
        if (width == 0) {
            return 0;
        }
        var gu1 = units.gu(1.0);
        var mod = (width % gu1);

        return mod == 0 ? width : width + (gu1 - mod);
    }

    onRootActionStateChanged: {
        if (rootActionState == undefined) {
            rightLabel = "";
            clockLabel.currentDate = null;
            enabled = false;
            return;
        }

        rightLabel = rootActionState.rightLabel ? rootActionState.rightLabel : "";
        enabled = rootActionState.visible;
    }
}
