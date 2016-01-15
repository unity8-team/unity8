/*
 * Copyright 2015 Canonical Ltd.
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
import QtQuick.Controls 1.3 as Controls

// Item which represents visual location of a menu item
// Also contains common convenience properties.
Item {
    id: root

    property var delegate: undefined
    property alias mnemonicAction: mnemonic

    /* Quick action. eg "F" from "_File" in the label. Only available while bar/popup is opened */
    Controls.Action {
        id: mnemonic
    }
}
