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
import "SettingsComponents"

MainView {
    // Note! applicationName needs to match the .desktop filename
    applicationName: "SettingsComponents"

    width: units.gu(42)
    height: units.gu(75)

    ListModel {
        id: mediaPlayerModel
        ListElement { song: "Mine"; artist: "Taylor Swift"; album: "Speak Now"; albumArt: "SettingsComponents/MediaPlayer/speak-now.jpg"}
        ListElement { song: "Stony Ground"; artist: "Richard Thompson"; album: "Electric"; albumArt: "SettingsComponents/MediaPlayer/electric.jpg"}
        ListElement { song: "Los Robots"; artist: "Kraftwerk"; album: "The Man-Machine"; albumArt: "SettingsComponents/MediaPlayer/the-man-machine.jpg"}
    }

    ListModel {
        id: timeZoneModel
        ListElement { city: "San Francisco"; time: "3:00am" }
        ListElement { city: "London"; time: "11:00am" }
        ListElement { city: "Rome"; time: "12:00am" }
    }

    ListModel {
        id: eventModel
        ListElement { color: "yellow"; name: "Lunch with Lola"; description: "Some nice Thai food in the bay area"; date: "1:10 PM" }
        ListElement { color: "green"; name: "Gym"; description: "Workout with John"; date: "6:30 PM" }
        ListElement { color: "red"; name: "Birthday Party"; description: "Don't forget your present!"; date: "9:00 PM" }
    }

    Page {
        title: "SettingsComponents"

        Flickable {
            id: flickable

            anchors.fill: parent
            contentWidth: column.width
            contentHeight: column.height

            Column {
                id: column

                width: flickable.width
                height: childrenRect.height

                SliderMenu {
                    text: i18n.tr("Slider")
                }

                ProgressBarMenu {
                    text: i18n.tr("ProgressBar")
                    indeterminate: true
                }

                ButtonMenu {
                    text: i18n.tr("Button")
                    controlText: i18n.tr("Hello world!")
                }

                CalendarMenu {
                    id: calendar
                    minimumDate: new Date(2013, 3, 2) // april 2013
                    maximumDate: new Date(2013, 6, 2) // july 2013
                }

                UserSessionMenu {
                    name: i18n.tr("Lola Chang")
                    icon: Qt.resolvedUrl("avatar.png")
                    active: true
                }

                MediaPlayerMenu {
                    property int index: 0

                    onPrevious: index = Math.max(index - 1, 0)
                    onNext: index = Math.min(index + 1, mediaPlayerModel.count - 1)

                    song: mediaPlayerModel.get(index).song;
                    artist: mediaPlayerModel.get(index).artist;
                    album: mediaPlayerModel.get(index).album;
                    albumArt: mediaPlayerModel.get(index).albumArt;
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
                            name: model.name
                            description: model.description
                            color: model.color
                            date: model.date
                        }
                    }
                }
            }
        }
    }
}
