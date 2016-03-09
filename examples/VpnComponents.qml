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
 *
 * Authored by Jonas G. Drange <jonas.drange@canonical.com>
 *
 * For a demonstration of the VPN components, you will need the Connectivity
 * module installed on your system.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Components.Popups 1.3
import Ubuntu.Connectivity 1.0
import Ubuntu.Settings.Vpn 0.1

MainView {
    width: units.gu(50)
    height: units.gu(90)

    PageStack {
        id: pageStack
        Component.onCompleted: push(root)

        Page {
            id: root
            title: i18n.tr("VPN")
            flickable: scrollWidget
            visible: false

            property var diag

            function openConnection(connection, isNew) {
                pageStack.push(vpnEditorDialog, {
                    "connection": connection,
                    "isNew": isNew
                });
            }

            function previewConnection(connection) {
                diag = PopupUtils.open(vpnPreviewDialog, root, {"connection": connection});
            }

            Flickable {
                id: scrollWidget
                anchors {
                    fill: parent
                    topMargin: units.gu(1)
                    bottomMargin: units.gu(1)
                }
                contentHeight: contentItem.childrenRect.height
                boundsBehavior: (contentHeight > root.height) ? Flickable.DragAndOvershootBounds : Flickable.StopAtBounds

                Column {
                    anchors { left: parent.left; right: parent.right }

                    VpnList {
                        id: list
                        anchors { left: parent.left; right: parent.right }
                        model: Connectivity.vpnConnections

                        onClickedConnection: root.previewConnection(connection)
                    }

                    ListItem.Caption {
                        // We do not yet support configuration files.
                        visible: false
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        text : i18n.tr("To add a VPN configuration, download its config file or configure it manually.")
                    }

                    ListItem.SingleControl {
                        control: Button {
                            text : i18n.tr("Add Manual Configuration…")
                            onClicked: Connectivity.vpnConnections.add(VpnConnection.OPENVPN)
                        }
                    }
                }
            }

            Component {
                id: vpnEditorDialog
                VpnEditor {
                    onTypeChanged: {
                        connection.remove();
                        pageStack.pop();
                        Connectivity.vpnConnections.add(type);
                    }
                }
            }

            Component {
                id: vpnPreviewDialog
                VpnPreviewDialog {
                    onChangeClicked: {
                        PopupUtils.close(root.diag);
                        root.openConnection(connection);
                    }
                }
            }

            Connections {
                target: Connectivity.vpnConnections
                onAddFinished: root.openConnection(connection, true)
            }
        }
    }
}
