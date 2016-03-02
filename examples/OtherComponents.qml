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
import Ubuntu.Settings.Components 0.1
import Ubuntu.Settings.Menus 0.1

Item {
    property string title: "Settings Components"

    ListModel {
        id: mediaPlayerModel
        ListElement { song: "You're The First, The Last, My Everything"; artist: "Barry White"; album: "Hot Soul"; albumArt: "artwork/beach.jpg"}
        ListElement { song: "Stony Ground"; artist: "Richard Thompson"; album: "Electric"; albumArt: "artwork/farm.jpg"}
        ListElement { song: "Los Robots"; artist: "Kraftwerk"; album: "The Man-Machine"; albumArt: "artwork/insane.jpg"}
    }

    ListModel {
        id: timeZoneModel
        ListElement { city: "San Francisco"; time: "3:00am" }
        ListElement { city: "London"; time: "11:00am" }
        ListElement { city: "Rome"; time: "12:00am" }
    }

    ListModel {
        id: eventModel
        ListElement { icon: "image://theme/calendar"; eventColor: "yellow"; text: "Lunch with Lola"; time: "1:10 PM" }
        ListElement { icon: "image://theme/calendar"; eventColor: "green"; text: "Gym"; time: "6:30 PM" }
        ListElement { icon: "image://theme/calendar"; eventColor: "red"; text: "Birthday Party"; time: "9:00 PM" }
    }

    Flickable {
        id: flickable

        anchors.fill: parent
        contentWidth: column.width
        contentHeight: column.height

        Column {
            id: column

            width: flickable.width
            height: childrenRect.height

            StandardMenu {
                text: i18n.tr("Standard Menu\nLook at me, I'm a new line.")
            }

            StandardMenu {
                iconSource: "image://theme/calendar"
                iconColor: "red"
                text: i18n.tr("Standard Menu")
                component: Component {
                    Button {
                        text: "Press Me"
                    }
                }
                backColor: Qt.rgba(1,1,1,0.1)
            }

            SliderMenu {
                id: slider
                text: i18n.tr("Slider")
                minimumValue: 0
                maximumValue: 100
                value: 20

                minIcon: "image://theme/audio-volume-low"
                maxIcon: "image://theme/audio-volume-high"
            }

            ProgressBarMenu {
                text: i18n.tr("ProgressBar")
                value: slider.value
                minimumValue: 0
                maximumValue: 100
            }

            ProgressValueMenu {
                text: i18n.tr("ProgressValue")
                value: slider.value
            }

            ButtonMenu {
                text: i18n.tr("Button")
                buttonText: i18n.tr("Hello world!")
            }

            CheckableMenu {
                text: i18n.tr("Checkable")
                checked: true
            }

            SwitchMenu {
                text: i18n.tr("Switch")
                checked: true
            }

            SectionMenu {
                text: i18n.tr("Section Starts Here")
                busy: true
            }

            SeparatorMenu {}

            CalendarMenu {
                id: calendar
            }

            UserSessionMenu {
                name: i18n.tr("Lola Chang")
                iconSource: "image://theme/contact"
                active: true
            }

            MediaPlayerMenu {
                id: mediaPlayer
                property int index: 0

                playerName: "Rhythmbox"
                playerIcon: Qt.resolvedUrl("../tests/artwork/rhythmbox.png")
                albumArt: mediaPlayerModel.get(index).albumArt;
                song: mediaPlayerModel.get(index).song;
                artist: mediaPlayerModel.get(index).artist;
                album: mediaPlayerModel.get(index).album;
                showTrack: mediaControl.playing
            }

            PlaybackItemMenu {
                id: mediaControl
                canPlay: true
                canGoNext: mediaPlayer.index < mediaPlayerModel.count - 1
                canGoPrevious: mediaPlayer.index > 0
                playing: false

                onPrevious: mediaPlayer.index = Math.max(mediaPlayer.index - 1, 0)
                onNext: mediaPlayer.index = Math.min(mediaPlayer.index + 1, mediaPlayerModel.count - 1)
                onPlay: { playing = !playing; }
            }

            AccessPointMenu {
                active: true
                secure: true
                adHoc: false
                signalStrength: 50
                text: "Access Point"

                onTriggered: active = !active
            }

            GroupedMessageMenu {
                text: "Group Message"
                count: "4100"
            }

            Column {
                anchors {
                    left: parent.left
                    right: parent.right
                }

                Repeater {
                    model: timeZoneModel

                    TimeZoneMenu {
                        city: model.city
                        time: model.time
                    }
                }
            }

            Column {
                anchors {
                    left: parent.left
                    right: parent.right
                }

                Repeater {
                    model: eventModel

                    EventMenu {
                        iconSource: model.icon
                        text: model.text
                        eventColor: model.eventColor
                        time: model.time
                        enabled: false
                    }
                }
            }

            Row {
                anchors {
                    left: parent.left
                    right: parent.right
                }

                spacing: units.gu(1)

                Label {
                    text: "StatusIcon"
                    anchors.verticalCenter: parent.verticalCenter
                }

                StatusIcon {
                    height: units.gu(5)
                    source: "image://theme/gps"
                }

                StatusIcon {
                    height: units.gu(5)
                    source: "image://theme/battery-caution"
                }

                StatusIcon {
                    height: units.gu(5)
                    source: "image://theme/missing,gpm-battery-000-charging"
                }
            }
        }
    }
}
