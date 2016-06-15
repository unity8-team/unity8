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
 * Authored by Andrea Cimitan <andrea.cimitan@canonical.com>
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import QtQuick.Layouts 1.1
import Ubuntu.Thumbnailer 0.1

ListItem.Empty {
    id: menu

    property bool showTrack: false
    property alias playerName: playerNameLabel.text
    property alias playerIcon: playerIcon.source

    property alias albumArt: albumArtImage.source
    property alias song: songLabel.text
    property alias artist: artistLabel.text
    property alias album: albumLabel.text

    __height: column.height + units.gu(2)
    Behavior on implicitHeight { UbuntuNumberAnimation {} }

    Column {
        id: column
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: menu.__contentsMargins
            rightMargin: menu.__contentsMargins
            verticalCenter: parent.verticalCenter
        }

        RowLayout {
            objectName: "player"
            id: playerRow
            spacing: menu.__contentsMargins
            visible: !showTrack
            anchors { left: parent.left; right: parent.right }

            Image {
                id: playerIcon
                Layout.preferredHeight: units.gu(5)
                Layout.preferredWidth: units.gu(5)
            }

            Label {
                id: playerNameLabel
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        RowLayout {
            objectName: "albumArt"
            id: trackRow
            spacing: units.gu(2)
            visible: showTrack
            anchors { left: parent.left; right: parent.right }

            UbuntuShape {
                Layout.preferredHeight: units.gu(8)
                Layout.preferredWidth: units.gu(8)

                image: Image {
                    id: albumArtImage
                    width:units.gu(8)
                    height:width
                    fillMode:Image.PreserveAspectFit
                    sourceSize:Qt.size(width, height)
                    anchors.centerIn: parent
                }
            }

            Column {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                spacing: units.gu(0.5)

                Label {
                    id: songLabel
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    visible: text !== ""
                    anchors { left: parent.left; right: parent.right }
                }

                Label {
                    id: artistLabel
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    visible: text !== ""
                    anchors { left: parent.left; right: parent.right }
                }

                Label {
                    id: albumLabel
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    fontSize: "small"
                    visible: text !== ""
                    anchors { left: parent.left; right: parent.right }
                }
            }
        }
    }
}
