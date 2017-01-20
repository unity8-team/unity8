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
import QtQuick.Layouts 1.2
import Ubuntu.Components 1.3

ColumnLayout {
    id: root
    spacing: root.contentSpacing

    property int contentSpacing

    Label {
        anchors {
            left: parent.left
            right: parent.right
        }
        text: i18n.tr("Location and language")
        textSize: Label.Large
        color: "white"
    }

    Column {
        anchors.centerIn: parent
        width: parent.width / 2
        spacing: root.contentSpacing

        TextField {
            anchors {
                left: parent.left
                right: parent.right
            }
            placeholderText: i18n.tr("Select your location")
            primaryItem: Icon {
                name: "location-active"
                height: parent.height * 0.7
                width: height
            }
        }

        TextField {
            anchors {
                left: parent.left
                right: parent.right
            }
            placeholderText: i18n.tr("Select your language")
            text: i18n.language
            primaryItem: Icon {
                name: "language-chooser"
                height: parent.height * 0.7
                width: height
            }
        }
    }
}
