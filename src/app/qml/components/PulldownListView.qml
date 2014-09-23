/*
 * Copyright: 2014 Canonical, Ltd
 *
 * This file is part of reminders
 *
 * reminders is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.3
import Ubuntu.Components 1.1

ListView {
    id: root

    signal refreshed()

    QtObject {
        id: priv
        property bool wasAtYBeginning: false
        property bool toBeReloaded: false
        property int initialContentY: 0
    }

    Label {
        width: root.width
        height: units.gu(3)
        anchors.bottom: root.contentItem.top;
        fontSize: 'medium'
        horizontalAlignment: Text.AlignHCenter
        text: priv.toBeReloaded ? i18n.tr("Release to refresh") : i18n.tr("Pull down to refresh")
        color: "#b3b3b3" 
    }

    onMovementStarted: {
        priv.wasAtYBeginning = atYBeginning
        priv.initialContentY = contentY
    }

    onContentYChanged: {
        if (dragging) {
            if (priv.wasAtYBeginning && priv.initialContentY - contentY > units.gu(5)) {
                priv.toBeReloaded = true
            }
            else {
                priv.toBeReloaded = false
            }
        }
    }

    onMovementEnded: {
        if (priv.toBeReloaded) {
            root.refreshed()
            priv.toBeReloaded = false;
        }
    }
}
