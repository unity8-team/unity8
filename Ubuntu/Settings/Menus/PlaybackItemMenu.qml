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
 * Authored by Nick Dedekind <nick.dedekind@gmail.com>
 */

import QtQuick 2.0
import Ubuntu.Settings.Components 0.1 as USC
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import QtQuick.Layouts 1.1

ListItem.Empty {
    id: menu

    property bool playing: false

    property bool canPlay: false
    property bool canGoNext: false
    property bool canGoPrevious: false

    signal next()
    signal play(bool play)
    signal previous()

    implicitHeight: layout.implicitHeight + units.gu(2)

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: units.gu(3)

        USC.IconVisual {
            objectName: "previousButton"

            Layout.preferredWidth: units.gu(5)
            Layout.preferredHeight: units.gu(5)

            source: "image://theme/media-skip-backward"
            color: {
                if (!enabled)
                    return Theme.palette.normal.backgroundText;
                return prevMA.pressed ? Theme.palette.selected.foreground : Theme.palette.normal.foregroundText;
            }
            enabled: canGoPrevious

            MouseArea {
                id: prevMA
                anchors.fill: parent
                onClicked: menu.previous()
            }
        }

        USC.IconVisual {
            objectName: "playButton"

            Layout.preferredWidth: units.gu(5)
            Layout.preferredHeight: units.gu(5)

            source: playing ? "image://theme/media-playback-pause" : "image://theme/media-playback-start"
            color: {
                if (!enabled)
                    return Theme.palette.normal.backgroundText;
                return playMA.pressed ? Theme.palette.selected.foreground : Theme.palette.normal.foregroundText;
            }
            enabled: canPlay

            MouseArea {
                id: playMA
                anchors.fill: parent
                onClicked: menu.play(!playing)
            }
        }

        USC.IconVisual {
            objectName: "nextButton"

            Layout.preferredWidth: units.gu(5)
            Layout.preferredHeight: units.gu(5)

            source: "image://theme/media-skip-forward"
            color: {
                if (!enabled)
                    return Theme.palette.normal.backgroundText;
                return nextMA.pressed ? Theme.palette.selected.foreground : Theme.palette.normal.foregroundText;
            }
            enabled: canGoNext

            MouseArea {
                id: nextMA
                anchors.fill: parent
                onClicked: menu.next()
            }
        }
    }
}
