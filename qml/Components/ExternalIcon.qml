/*
 * Copyright (C) 2016 Canonical, Ltd.
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
import Ubuntu.Components 1.3

/*! \brief Display icon for an app

    This widget shows the specified image, with standard settings for showing
    an app icon.

    If you make any important changes here, you may also want to update
    kArtShapeHolderCode in CardCreator.js, since that is used to show app
    icons in the dash.
 */

ProportionalShape {
    id: root

    property alias icon: iconImage.source
    property alias cache: iconImage.cache

    readonly property alias status: iconImage.status

    // It's bad form to bleed through, so we provide a color of last resort
    backgroundColor: UbuntuColors.porcelain

    sourceHorizontalAlignment: UbuntuShape.AlignHCenter
    sourceVerticalAlignment: UbuntuShape.AlignVCenter

    source: Image {
        id: iconImage
        sourceSize.width: root.width
        sourceSize.height: root.height
    }
}
