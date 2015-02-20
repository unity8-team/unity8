/*
 * Copyright (C) 2014 Canonical, Ltd.
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

import QtQuick 2.0
/*!
 \brief A filter for volume keys

A filter which treats volume keys as single tri-state key with the states:
VolumeUp Pressed, VolumeDown Pressed or Volume Up+Down pressed
*/
QtObject {
    id: root

    signal volumeUpReleased()
    signal volumeDownReleased()
    signal bothVolumeKeysPressed()

    property bool volumeUpKeyPressed: false
    property bool volumeDownKeyPressed: false
    property bool aVolumeKeyWasReleased: true

    function onKeyPressed(event) {
        var key = event.key
        if (key == Qt.Key_VolumeUp) {
            volumeUpKeyPressed = true;
        } else if (key == Qt.Key_VolumeDown) {
            volumeDownKeyPressed = true;
        }

        if (volumeUpKeyPressed && volumeDownKeyPressed) {
            if (aVolumeKeyWasReleased) {
                aVolumeKeyWasReleased = false;
                bothVolumeKeysPressed();
            }
        } else if (event.isAutoRepeat) {
            /* This is tricky, but it allows events to get through when
             * a single volume key is held down
             */
            if (key == Qt.Key_VolumeUp) {
                volumeUpReleased();
            } else if (key == Qt.Key_VolumeDown) {
                volumeDownReleased();
            }
        }
    }

    function onKeyReleased(event) {
        var key = event.key
        if (key == Qt.Key_VolumeUp) {
            aVolumeKeyWasReleased = true;
            volumeUpKeyPressed = false;
            volumeUpReleased();
        } else if (key == Qt.Key_VolumeDown) {
            aVolumeKeyWasReleased = true;
            volumeDownKeyPressed = false;
            volumeDownReleased();
        }
    }
}
