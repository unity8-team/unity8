/*
 * Copyright (C) 2014 Canonical, Ltd.
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

/*! Widget for See More/Less functionality. */

Item {
    id: root

    property bool canSeeMore: true

    signal toggled()

    implicitHeight: seeMoreLabel.height + units.gu(2)

    Label {
        id: seeMoreLabel
        objectName: "seeMoreLabel"

        anchors.centerIn: parent

        text: canSeeMore ? i18n.tr("See more") : i18n.tr("See less")
        // TODO: Fix requiring Palette update
        color: "grey" //Theme.palette.selected.backgroundText
        font.weight: Font.Bold

        MouseArea {
            id: seeMoreMouseArea
            enabled: seeMoreLabel.visible
            anchors.fill: parent
            onClicked: root.toggled();
        }
    }
}
