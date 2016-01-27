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
 * Authors:
 *      Renato Araujo Oliveira Filho <renato@canonical.com>
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem

ListItem.Header {
    id: menuItem
    property alias busy: indicator.running
    __foregroundColor: theme.palette.normal.backgroundText

    ActivityIndicator {
        id: indicator
        objectName: "indicator"

        anchors {
            margins: units.gu(0.5)
            right: parent.right
        }
        height: parent.height - (anchors.margins * 2)
        width: height
        anchors.verticalCenter: parent.verticalCenter
    }
}
