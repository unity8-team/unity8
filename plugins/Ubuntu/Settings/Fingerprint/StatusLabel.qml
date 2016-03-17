/*
 * Copyright 2016 Canonical Ltd.
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
 */

import QtQuick 2.4
import Ubuntu.Components 1.3

Item {
    id: root
    property string initialText

    property int origX: 0

    Component.onCompleted: origX = label.x

    function setText(text) {
        if (text == label.text) {
            return;
        }
        function outStoppedHandler () {
            label.text = text;
            label.x = units.gu(50)
            inAnim.start();
            outAnim.stopped.disconnect(outStoppedHandler);
        }
        outAnim.stopped.connect(outStoppedHandler);
        outAnim.start();
    }

    Label {
        id: label

        horizontalAlignment: Text.AlignHCenter
        width: parent.width
        height: units.gu(4)
        wrapMode: Text.WordWrap
        font.pixelSize: units.gu(3.3)
        text: initialText
    }

    SequentialAnimation {
        id: outAnim
        alwaysRunToEnd: true
        NumberAnimation {
            target: label
            property: "x"
            to: -units.gu(50)
            duration: UbuntuAnimation.SlowDuration
        }
    }

    SequentialAnimation {
        id: inAnim
        alwaysRunToEnd: true
        NumberAnimation {
            target: label
            property: "x"
            to: root.origX
            duration: UbuntuAnimation.SlowDuration
        }
    }
}
