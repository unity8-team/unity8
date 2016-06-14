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

import Biometryd 0.0
import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Settings.Fingerprint 0.1

Item {
    property int direction: FingerprintReader.NotAvailable
    opacity: direction !== FingerprintReader.NotAvailable ? 1 : 0
    Behavior on opacity { UbuntuNumberAnimation {} }

    UbuntuNumberAnimation {
        id: rotationAnimation
        alwaysRunToEnd: true

        target: directionContainer
        property: "rotation"

        function normalizeAngle(v) {
            if (v < 0)
                return 360 + v;
            else
                return v % 360;
        }

        onStopped: {
            directionContainer.rotation = normalizeAngle(directionContainer.rotation);
        }
    }

    onDirectionChanged: {
        var v1 = rotation;
        var v2;
        var length;

        switch (direction) {
        case FingerprintReader.North:
            v2 = 0; break;
        case FingerprintReader.NorthEast:
            v2 = 45; break;
        case FingerprintReader.East:
            v2 = 90; break;
        case FingerprintReader.SouthEast:
            v2 = 135; break;
        case FingerprintReader.South:
            v2 = 180; break;
        case FingerprintReader.SouthWest:
            v2 = 225; break;
        case FingerprintReader.West:
            v2 = 270; break;
        case FingerprintReader.NorthWest:
            v2 = 315; break;
        }

        length = Math.min(Math.abs(v1 - v2),
                     Math.abs(v1 - 360 - v2),
                     Math.abs(v1 + 360 - v2));

        if (length !== 180)
            length = length % 180;

        if (((length + v1) % 360) === v2)
            v1 = v1 + length;
        else
            v1 = v1 -length;

        rotationAnimation.from = rotation;
        rotationAnimation.to = v1;
        rotationAnimation.start();
    }

    Icon {
        id: directionArrow
        objectName: "fingerprintDirectionLabel"
        anchors {
            top: parent.top
            topMargin: -units.gu(2)
            horizontalCenter: parent.horizontalCenter
        }
        width: units.gu(5)
        height: width

        name: "down"
        color: theme.palette.normal.activity
    }
}
