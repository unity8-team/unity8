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
import Ubuntu.Components 0.1

Item {
    property alias name: nameLabel.text
    property alias description: descriptionLabel.text
    property alias color: icon.color
    property string date

    Row {
        anchors.left: parent.left
        spacing: units.gu(1)

        Rectangle {
            id: icon
            width: units.gu(2)
            height: units.gu(2)
            opacity: 0.5
        }

        Column {
            Label {
                id: nameLabel
                font.weight: Font.DemiBold
            }

            Label {
                id: descriptionLabel
                fontSize: "small"
            }
        }
    }

    Label {
        id: dateLabel
        anchors.right: parent.right
        text: date //Qt.formatTime(date)
    }
}
