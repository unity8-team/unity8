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

import QtQuick 2.0
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem
import QtQuick.Layouts 1.1

ListItem.Empty {
    id: menu

    property bool running: false
    property alias playerName: playerNameLabel.text
    property alias playerIcon: playerIcon.source

    property alias albumArt: albumArtImage.source
    property alias song: songLabel.text
    property alias artist: artistLabel.text
    property alias album: albumLabel.text

    __height: column.height + units.gu(2)
    Behavior on implicitHeight { UbuntuNumberAnimation {} }

    ColumnLayout {
        id: column
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: units.gu(1)
            leftMargin: menu.__contentsMargins
            rightMargin: menu.__contentsMargins
        }

        RowLayout {
            objectName: "player"
            id: playerRow
            spacing: menu.__contentsMargins
            visible: !running

            Image {
                id: playerIcon
                Layout.preferredHeight: units.gu(5)
                Layout.preferredWidth: units.gu(5)
            }

            Label {
                id: playerNameLabel
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        RowLayout {
            objectName: "albumArt"
            id: trackRow
            width: menu.width
            spacing: units.gu(2)
            visible: running

            UbuntuShape {
                Layout.preferredHeight: units.gu(10)
                Layout.preferredWidth: units.gu(10)

                image: Image {
                    id: albumArtImage
                }
            }

            ColumnLayout {
                anchors.verticalCenter: parent.verticalCenter

                Label {
                    id: songLabel
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Label {
                    id: artistLabel
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Label {
                    id: albumLabel
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    fontSize: "small"
                }
            }
        }
    }
}
