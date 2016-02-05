/*
 * Copyright (C) 2016 Canonical Ltd.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3,
 * as published by the Free Software Foundation.
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
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

Dialog {
    id: preview

    property var connection

    signal changeClicked(var connection)

    // TRANSLATORS: %1 is the hostname of a VPN connection
    title: i18n.tr("VPN “%1”").arg(connection.remote)

    states: [
        State {
            name: "CERT_NONE"
            when: 1 == 1
            StateChangeScript { script: contentLoader.setSource("NoCert.qml") }
        },
        State {
            name: "CERT_INVALID"
            when: 1 == 0
            StateChangeScript { script: contentLoader.setSource("InvalidCert.qml") }
        },
        State {
            name: "VPN_ALL_TRAFFIC_WITH_DNS"
            when: 1 == 0
            StateChangeScript { script: contentLoader.setSource("AllTrafficWithDns.qml") }
        },
        State {
            name: "VPN_ALL_TRAFFIC_WITHOUT_DNS"
            when: 1 == 0
            StateChangeScript { script: contentLoader.setSource("AllTrafficWithoutDns.qml") }
        },
        State {
            name: "VPN_SOME_TRAFFIC"
            when: 1 == 0
            StateChangeScript { script: contentLoader.setSource("SomeTraffic.qml") }
        },
        State {
            name: "VPN_SET_UP_UNUSED"
            when: 1 == 0
            StateChangeScript { script: contentLoader.setSource("SetUpUnused.qml") }
        },
        State {
            name: "VPN_NOT_INSTALLED_NO_SPECIFIC_ROUTES"
            when: 1 == 0
            StateChangeScript { script: contentLoader.setSource("NotInstalledWithRoutes.qml") }
        },
        State {
            name: "VPN_NOT_INSTALLED_WITH_SPECIFIC_ROUTES"
            when: 1 == 0
            StateChangeScript { script: contentLoader.setSource("NotInstalledWithoutRoutes.qml") }
        }
    ]

    Loader {
        id: contentLoader
        anchors { left: parent.left; right: parent.right; }
    }

    Row {
        spacing: units.gu(2)

        Button {
            id: removeButton
            width: (parent.width / 2) - (parent.spacing / 2)
            text: i18n.tr("Remove")
            color: UbuntuColors.red
            onClicked: connection.remove()
        }

        Button {
            width: removeButton.width
            text: i18n.tr("Change")
            onClicked: changeClicked(connection)
        }
    }
}

