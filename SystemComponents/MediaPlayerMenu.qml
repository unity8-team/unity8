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

    property alias model: list.model

    signal play(int index)

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

        ListView {
            id: list

            width: currentItem.width
            height: currentItem.height
            orientation: ListView.Horizontal
            highlightMoveDuration: 500

            delegate: Row {
                width: mediaPlayerMenu.width
                spacing: units.gu(2)

                UbuntuShape {
                    width: units.gu(14)
                    height: width

                    image: Image {
                        source: model.albumArt
                    }
                }

                Column {
                    spacing: units.gu(1)

                    Label {
                        text: model.song
                        font.weight: Font.DemiBold
                    }

                    Label {
                        text: model.artist
                    }

                    Label {
                        text: model.album
                    }
                }
            }
        }

        Row {
            id: controlsRow

            readonly property real buttonsWidth: units.gu(8)

            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(4)

            Button {
                width: controlsRow.buttonsWidth
                iconSource: "MediaPlayer/DoubleLeftArrow.png"
                onClicked: list.currentIndex = Math.max(list.currentIndex - 1, 0)
            }

            Button {
                objectName: "playButton"
                width: controlsRow.buttonsWidth
                iconSource: "MediaPlayer/RightArrow.png"
                onClicked: mediaPlayerMenu.play(list.currentIndex)
            }

            Button {
                width: controlsRow.buttonsWidth
                iconSource: "MediaPlayer/DoubleRightArrow.png"
                onClicked: list.currentIndex = Math.min(list.currentIndex + 1, model.count - 1)
            }
        }
    }
}
