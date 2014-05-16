/*
 * Copyright 2012 Canonical Ltd.
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

import QtQuick 2.0
import Ubuntu.Components 0.1

/*
  This delegate is styled using the following properties:
  - backgroundImage: image source for the bar
  - backgroundImageHeight: specifies the height of the image to be used;
        if not specified, the images source height will be used
  - thumbImage: image source for the thumb
  - thumbWidth, thumbHeight: width and height of the thumb; source measurements
        will be used if not specified
  - thumbSpacing: spacing between the thumb and the bar; 0 if not specified
  */

Item {

    id: main
    anchors.fill: parent

    property Item bar: backgroundShape
    property Item thumb: thumbShape

    property real normalizedValue: SliderUtils.normalizedValue(styledItem)
    property real thumbSpacing: 0.0
    property real thumbSpace: backgroundShape.width - (2.0 * thumbSpacing + thumbWidth)
    property real thumbWidth: units.gu(1.5)
    property real thumbHeight: units.gu(1.5)

    property string backgroundImage: "assets/zoom_bar@18.png"
    property string thumbImage: "assets/zoom_point@18.png"

    Image {
        id: backgroundShape
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        source: backgroundImage
        height: sourceSize.height
    }

    Image {
        id: thumbShape
        objectName: "sliderThumb"

        x: backgroundShape.x + thumbSpacing + normalizedValue * thumbSpace
        y: backgroundShape.y + thumbSpacing
        width: thumbWidth
        height: thumbHeight
        anchors.verticalCenter: backgroundShape.verticalCenter
        source: thumbImage
    }

    // set styledItem's implicitHeight to the thumbShape's height
    // this can also control the default sensing area
    Binding {
        target: styledItem
        property: "implicitHeight"
        value: thumbShape.height + 2.0 * thumbSpacing
    }
}
