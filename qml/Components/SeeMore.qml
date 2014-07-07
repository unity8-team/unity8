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

/*! Widget for See More/Less functionality functionality. */

Item {
    id: root

    property alias enableSeeMore: seeMoreMouseArea.enabled
    property alias enableSeeLess: seeLessMouseArea.enabled

    signal seeMoreClicked()
    signal seeLessClicked()

    implicitHeight: seeMoreLabel.height + units.gu(2)

    Row {
        anchors.centerIn: parent
        spacing: units.gu(2)

        Label {
            id: seeMoreLabel
            objectName: "seeMoreLabel"
            text: i18n.tr("See more")
            opacity: root.enableSeeMore ? 0.8 : 0.4
            // TODO: Fix requiring Palette update
            color: "grey" //Theme.palette.selected.backgroundText
            font.weight: Font.Bold

            MouseArea {
                id: seeMoreMouseArea
                enabled: false
                anchors.fill: parent
                onClicked: root.seeMoreClicked();
            }
        }

        Image {
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            width: units.dp(2)
            source: "ListItems/graphics/ListItemDividerVertical.png"
        }

        Label {
            objectName: "seeLessLabel"
            text: i18n.tr("See less")
            opacity: root.enableSeeLess ? 0.8 : 0.4
            // TODO: Fix requiring Palette update
            color: "grey" //Theme.palette.selected.backgroundText
            font.weight: Font.Bold

            MouseArea {
                id: seeLessMouseArea
                enabled: false
                anchors.fill: parent
                onClicked: root.seeLessClicked()
            }
        }
    }
}
