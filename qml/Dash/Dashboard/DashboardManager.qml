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
import QtQuick.Window 2.2
import Ubuntu.Components 1.3
import Unity 0.2
import "../../Components"

MainView {
    id: root

    anchors.fill: parent

    Scopes { id: scopes }

    PageHeader {
        id: pageHeader
        title: i18n.tr("Manage Dashboard")
    }

    ListView {
        id: categoriesContainer
        objectName: "categoriesContainer"

        anchors {
            top: pageHeader.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        clip: true
        model: scopes.overviewScope ? scopes.overviewScope.categories : null
        delegate: DashboardManagerDelegate {
            onRequestFavorite: scopes.setFavorite(scopeId, favorite);
        }
    }

    Binding {
        target: scopes.overviewScope
        property: "isActive"
        value: root.visible
    }
}
