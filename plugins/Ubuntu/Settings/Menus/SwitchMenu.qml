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

import QtQuick 2.4
import Ubuntu.Components 1.3

StandardMenu {
    id: menu

    property bool checked: false

    onClicked: menu.checked = !menu.checked

    component: Component {
        Switch {
            id: switcher
            objectName: "switcher"
            property bool enableCheckConnection: true

            Component.onCompleted: {
                checked = menu.checked;
            }

            // FIXME : create a bi-directional feedback component
            onCheckedChanged: {
                if (!enableCheckConnection) {
                    return;
                }
                var oldEnable = enableCheckConnection;
                enableCheckConnection = false;

                menu.checked = checked;
                menu.triggered(menu.checked);

                enableCheckConnection = oldEnable;
            }

            Connections {
                target: menu
                onCheckedChanged: {
                    if (!switcher.enableCheckConnection) {
                        return;
                    }
                    var oldEnable = switcher.enableCheckConnection;
                    switcher.enableCheckConnection = false;

                    switcher.checked = menu.checked;

                    switcher.enableCheckConnection = oldEnable;
                }
            }
        }
    }
}
