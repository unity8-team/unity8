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

import QtQuick 2.0
import Ubuntu.Components 0.1 as Components
import Ubuntu.Settings.Components 0.1 as USC
import Ubuntu.Components.ListItems 0.1 as ListItems
import QtQuick.Layouts 1.1

ListItems.Empty {
    id: menu

    property alias iconSource: iconVisual.source
    property alias text: label.text
    property alias iconColor: iconVisual.color
    property alias component: componentLoader.sourceComponent

    RowLayout {

        anchors {
            fill: parent
            leftMargin: menu.__contentsMargins
            rightMargin: menu.__contentsMargins
        }
        spacing: menu.__contentsMargins

        USC.IconVisual {
            id: iconVisual
            visible: status == Image.Ready
            color: Theme.palette.selected.backgroundText

            readonly property real size: Math.min(units.gu(3), parent.height - menu.__contentsMargins)

            height: size
            width: size
            Layout.alignment: Qt.AlignVCenter
        }

        Components.Label {
            id: label
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            elide: Text.ElideRight
            opacity: label.enabled ? 1.0 : 0.5
        }

        Loader {
            id: componentLoader
        }
    }
}
