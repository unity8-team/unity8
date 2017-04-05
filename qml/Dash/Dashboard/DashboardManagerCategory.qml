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
import "../../Components"
import ".."

ListItem {
    id: root
    objectName: name + "Section"

    signal requestFavorite(string scopeId, bool favorite)

    property alias categoryId: categoryView.categoryId
    property alias categoryName: categoryView.categoryName
    property alias categoryResults: categoryView.model

    // Expose for testing
    readonly property int index: model.index

    implicitHeight: layout.height
    divider.visible: false

    Item {
        id: layout

        height: categoryView.contentHeight
        width: parent.width

        ListView {
            id: categoryView
            objectName: "categoryView"

            property string categoryId
            property string categoryName

            readonly property bool isPinnedToDashboard: categoryId === "favorites"
            readonly property bool isAlsoInstalled: categoryId === "other"

            height: contentHeight
            width: parent.width

            header: DashSectionHeader {
                visible: results.count > 0
                fontSize: "small"
                labelOpacity: 0.75
                text: {
                    if (categoryName === "Favorites") {
                        return i18n.tr("Dashboard");
                    } else if (categoryName === "Non Favorites") {
                        return i18n.tr("Also Installed");
                    } else {
                        return categoryName;
                    }
                }
            }

            displaced: Transition {
                UbuntuNumberAnimation {
                    properties: "y"
                    duration: UbuntuAnimation.FastDuration
                }
            }

            delegate: DashboardManagerScope {
                scopeIcon: model.art
                scopeId: model.scopeId
            }
        }
    }
}
