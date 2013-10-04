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
 *      Nick Dedekind <nick.dedekind@canonical.com>
 */

import QtQuick 2.0
import Ubuntu.Components 0.1 as Components
import Ubuntu.Components.ListItems 0.1 as ListItem

ListItem.Empty {
    id: menu

    property bool checked: false

    signal check(bool checked)

    onCheckedChanged: {
        // Can't rely on binding. Checked is assigned on click.
        checkbox.checked = checked;
    }

    onClicked: {
        checkbox.clicked()
    }

    Components.CheckBox {
        id: checkbox
        objectName: "checkbox"
        anchors {
            left: parent.left
            leftMargin: menu.__contentsMargins
            verticalCenter: parent.verticalCenter
        }

        Component.onCompleted: {
            checked = menu.checked;
        }

        // FIXME : should use Checkbox.toggled signal
        // lp:~nick-dedekind/ubuntu-ui-toolkit/checkbox.toggled
        onClicked: {
            menu.check(checkbox.checked);
        }
    }

    Components.Label {
        text: menu.text
        anchors {
            left: checkbox.right
            leftMargin: menu.__contentsMargins
            rightMargin: menu.__contentsMargins
            verticalCenter: parent.verticalCenter
        }
    }
}
