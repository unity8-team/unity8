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
import Ubuntu.Components 0.1

BasicMenu {
    id: mediaPlayerMenu

    property alias albumArt: albumArtImage.source
    property alias song: songLabel.text
    property alias artist: artistLabel.text
    property alias album: albumLabel.text

    signal next()
    signal play()
    signal previous()

//    ItemStyle.class: "settings-menu mediaplayer-menu"

    implicitHeight: column.height + units.gu(4)

    Column {
        id: column
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: units.gu(2)
        }
        spacing: units.gu(2)

        Row {
            width: mediaPlayerMenu.width
            spacing: units.gu(2)

            UbuntuShape {
                width: units.gu(14)
                height: width

                image: Image {
                    id: albumArtImage
                }
            }

            Column {
                spacing: units.gu(1)

                Label {
                    id: songLabel
                    color: "#757373"
                    ItemStyle.class: "label label-song"
                }

                Label {
                    id: artistLabel
                    color: "#757373"
                    ItemStyle.class: "label label-artist"
                }

                Label {
                    id: albumLabel
                    color: "#757373"
                    ItemStyle.class: "label label-album"
                }
            }
        }

        Row {
            id: controlsRow

            readonly property real buttonsWidth: units.gu(8)

            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(4)

            Button {
                objectName: "previousButton"
                width: controlsRow.buttonsWidth
                iconSource: "MediaPlayer/DoubleLeftArrow.png"
                onClicked: mediaPlayerMenu.previous()
                text: ""
            }

            Button {
                objectName: "playButton"
                width: controlsRow.buttonsWidth
                iconSource: "MediaPlayer/RightArrow.png"
                onClicked: mediaPlayerMenu.play()
                text: ""
            }

            Button {
                objectName: "nextButton"
                width: controlsRow.buttonsWidth
                iconSource: "MediaPlayer/DoubleRightArrow.png"
                onClicked: mediaPlayerMenu.next()
                text: ""
            }
        }
    }
}
