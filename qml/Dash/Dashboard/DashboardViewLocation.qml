/*
 * Copyright (C) 2017 Canonical, Ltd.
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

import QtQuick 2.4
import QtPositioning 5.6
import QtLocation 5.6
import Ubuntu.Components 1.3

Column {
    id: root
    spacing: root.contentSpacing

    property int contentSpacing

    Plugin {
        id: osmPlugin
        name: "osm"
        PluginParameter { name: "osm.useragent"; value: "Unity 8 Dashboard" }
    }

    GeocodeModel {
        id: geo
        autoUpdate: false
        plugin: osmPlugin
        query: src.position.coordinate
        onStatusChanged: {
            print("Reverse geocoder status changed:", status)
            if (status == GeocodeModel.Ready) {
                print("Ready, results:", count)
                var address = get(0).address;
                print("LOCATION:", address.text)
                locationEdit.text = address.district + ", " + address.city + ", " + address.state + ", " + address.country;
            } else if (status == GeocodeModel.Error) {
                console.error("Reverse geocoder error:", errorString, error);
            }
        }
    }

    PositionSource {
        id: src
        active: false

        onPositionChanged: {
            var coord = position.coordinate;
            console.log("Coordinate:", coord, "(", coord.latitude, coord.longitude, ")");
            geo.update();
        }
    }

    Component.onCompleted: {
        if (src.valid) {
            src.update(); // Request a single update of the position
        } else {
            console.warn("No supported positioning methods")
        }
    }

    Label {
        anchors {
            left: parent.left
            right: parent.right
        }
        text: i18n.tr("Location and language")
        textSize: Label.Large
        wrapMode: Label.WordWrap
        maximumLineCount: 2
        color: "white"
    }

    Column {
        anchors {
            left: parent.left
            right: parent.right
        }
        spacing: root.contentSpacing

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.max(units.gu(15), root.width/3)
            height: width
            source: "image://theme/language-chooser"
        }

        TextField {
            id: locationEdit
            enabled: !checkbox.checked
            anchors {
                left: parent.left
                right: parent.right
            }
            placeholderText: i18n.tr("Select your location")
            primaryItem: Icon {
                name: "location-active"
                height: parent.height * 0.7
                width: height
                MouseArea {
                    anchors.fill: parent
                    enabled: src.valid
                    onClicked: src.update();
                }
            }
        }

        TextField {
            id: languageEdit
            anchors {
                left: parent.left
                right: parent.right
            }
            placeholderText: i18n.tr("Select your language")
            primaryItem: Icon {
                name: "language-chooser"
                height: parent.height * 0.7
                width: height
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: childrenRect.height
            CheckBox {
                id: checkbox
                anchors.left: parent.left
            }
            Label {
                anchors {
                    left: checkbox.right
                    right: parent.right
                    leftMargin: root.contentSpacing
                }
                text: i18n.tr("Do not allow Scopes to use your location and language")
                wrapMode: Label.WordWrap
                maximumLineCount: 2
                color: "white"
                MouseArea {
                    anchors.fill: parent
                    onClicked: checkbox.trigger()
                }
            }
        }
    }
}
