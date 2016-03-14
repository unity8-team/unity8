/*
 * Copyright 2016 Canonical Ltd.
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
 */

import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3

Page {
    id: root

    states: [
    ]

    header: PageHeader {
        leadingActionBar.actions: []
        visible: false
    }

    Item {
        id: actions
        anchors {
            fill: parent
            margins: units.gu(2)
        }

        Label {
            id: statusLabel
            anchors { left: parent.left; right: parent.right }
            horizontalAlignment: Text.AlignHCenter
            text: i18n.dtr("ubuntu-settings-components", "Place your finger on the home button.")
        }

        RowLayout {
            spacing: units.gu(2)
            anchors {
                left: parent.left;
                right: parent.right
                bottom: parent.bottom
            }

            Button {
                id: cancelButton
                text: i18n.dtr("ubuntu-settings-components", "Cancel")
                Layout.fillWidth: true
            }

            Button {
                id: doneButton
                color: UbuntuColors.green
                text: i18n.dtr("ubuntu-settings-components", "Done")
                Layout.fillWidth: true
            }
        }

    }
}
