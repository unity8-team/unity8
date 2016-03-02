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
import Ubuntu.Components.ListItems 1.3 as ListItems

ListItems.Empty {
    id: menu

    property alias iconSource: iconVisual.source
    property alias text: label.text
    property alias time: dateLabel.text
    property alias eventColor: iconVisual.color

    Icon {
        id: iconVisual
        source: "image://theme/calendar"
        visible: source != ""
        color: theme.palette.normal.backgroundText

        height: Math.min(units.gu(3), parent.height - units.gu(1))
        width: height

        anchors {
            left: parent.left
            leftMargin: menu.__contentsMargins
            verticalCenter: parent.verticalCenter
        }
    }

    Label {
        id: label
        anchors {
            verticalCenter: parent.verticalCenter
            left: iconVisual.visible ? iconVisual.right : parent.left
            leftMargin: menu.__contentsMargins
            right: dateLabel.left
            rightMargin: menu.__contentsMargins
        }
        elide: Text.ElideRight
        maximumLineCount: 1
        opacity: enabled ? 1.0 : 0.5
    }

    Label {
        id: dateLabel

        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: menu.__contentsMargins
        }
        opacity: enabled ? 1.0 : 0.5
    }
}
