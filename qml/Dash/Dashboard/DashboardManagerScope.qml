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
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems
import Unity 0.2
import "../../Components"

ListItem {
    readonly property alias innerLayoutPadding: innerLayout.padding

    property alias scopeIcon: scopeArtIcon.source
    property alias scopeId: innerLayout.scopeId

    height: innerLayout.height
    width: parent.width

    divider.visible: false

    ListItems.ThinDivider {
        visible: index != 0
    }

    ListItemLayout {
        id: innerLayout
        objectName: "layout" + index

        property string scopeId

        ProportionalShape {
            id: scopeArt
            height: units.gu(4.5)
            SlotsLayout.position: SlotsLayout.Leading

            aspect: UbuntuShape.Flat
            source: Image {
                id: scopeArtIcon

                sourceSize.height: scopeArt.height
                sourceSize.width: scopeArt.width
            }
        }

        title.text: scopeId

        // FIXME: update when pin icon is added to theme
        Icon {
            objectName: "pinIcon"

            height: units.gu(2)
            width: units.gu(2)
            source: {
                if (categoryView.isPinnedToDashboard) {
                    return "graphics/pinned.png"
                } else if (categoryView.isAlsoInstalled) {
                    return "graphics/unpinned.png"
                } else {
                    return ""
                }
            }

            MouseArea {
                objectName: "favoriteButton"

                anchors.fill: parent
                onClicked: {
                    root.requestFavorite(scopeId, !categoryView.isPinnedToDashboard)
                }
            }
        }
    }
}
