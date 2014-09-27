/*
 * Copyright: 2014 Canonical, Ltd
 *
 * This file is part of reminders-app
 *
 * reminders-app is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.3
import Ubuntu.Components 1.1

ProgressBar {
    // Using dp and not gu because we want always a little bar, that doesn't
    // change with screen size
    height: units.dp(3)
    width: parent.width

    value: 0.3

    showProgressPercentage: false

    SequentialAnimation on x {
        loops: Animation.Infinite
        running: parent.visible

        PropertyAnimation {
            to: 2/3 * parent.width
            duration: 1000
        }

        PropertyAnimation {
            to: 0
            duration: 1000
        }
    }
}
