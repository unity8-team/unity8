/*
 * Copyright 2013 Canonical Ltd.
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

Item {
    property size cameraResolution;
    property int viewFinderHeight;
    property int viewFinderWidth;
    property int viewFinderOrientation;

    property int __cameraWidth: Math.abs(viewFinderOrientation) == 90 ?
                                cameraResolution.height : cameraResolution.width
    property int __cameraHeight: Math.abs(viewFinderOrientation) == 90 ?
                                 cameraResolution.width : cameraResolution.height

    property real widthScale: viewFinderWidth / __cameraWidth
    property real heightScale: viewFinderHeight / __cameraHeight

    width: (widthScale <= heightScale) ? viewFinderWidth : __cameraWidth * heightScale
    height: (widthScale <= heightScale) ? __cameraHeight * widthScale : viewFinderHeight
}
