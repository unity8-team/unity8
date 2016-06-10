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
 *
 * Authored by Jonas G. Drange <jonas.drange@canonical.com>
 */

import QtQuick 2.4
import Ubuntu.Components 1.3

Item {
    id: root

    property string initialText
    property int origX: 0
    readonly property alias text: label.text

    signal slideStarted()
    signal slideCompleted()

    Component.onCompleted: origX = label.x

    function setText(text, noAnimation) {
        if (noAnimation === true) {
            label.text = text;
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

        font.pixelSize: units.gu(3.3)
        horizontalAlignment: Text.AlignHCenter
        height: units.gu(4)
        text: initialText
        width: parent.width
        wrapMode: Text.WordWrap
    }

    NumberAnimation {
        id: outAnim

        alwaysRunToEnd: true
        duration: UbuntuAnimation.FastDuration
        easing: UbuntuAnimation.StandardEasing
        onStarted: root.slideStarted()
        property: "x"
        target: label
        to: -units.gu(50)
    }

    NumberAnimation {
        id: inAnim

        alwaysRunToEnd: true
        duration: UbuntuAnimation.FastDuration
        easing: UbuntuAnimation.StandardEasing
        onStopped: root.slideCompleted()
        property: "x"
        target: label
        to: root.origX
    }
}
