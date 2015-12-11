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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Settings.Components 0.1
import Ubuntu.Settings.Menus 0.1

MainView {
    id: mainView
    // Note! applicationName needs to match the .desktop filename
    applicationName: "SettingsComponents"

    width: units.gu(42)
    height: units.gu(75)

    Component.onCompleted: {
        theme.name = "Ubuntu.Components.Themes.SuruGradient"
    }

    ListModel {
        id: pages
        ListElement { source: "OtherComponents.qml" }
        ListElement { source: "MessageComponents.qml" }
        ListElement { source: "TransferComponents.qml" }
    }

    Page {
        title: listView.currentItem ? listView.currentItem.item.title : "Components"
        clip: true

        ListView {
            id: listView
            model: pages
            anchors.fill: parent

            orientation: ListView.Horizontal
            snapMode: ListView.SnapOneItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            boundsBehavior: Flickable.StopAtBounds

            delegate: Loader {
                width: ListView.view.width
                height: ListView.view.height

                source: model.source
            }
        }

    }
}
