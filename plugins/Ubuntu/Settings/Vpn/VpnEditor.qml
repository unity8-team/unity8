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
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.Components.Popups 1.3

Dialog {
    id: editor
    objectName: "vpnEditorDialog"
    title: i18n.tr("Set up VPN")

    property var connection

    // If isNew, we delete it on cancel.
    property var isNew

    signal typeChanged(var connection, int type)

    // XXX: Most of this commit function deals with bug lp:1546559.
    // Each remote variable is changed in a chain of events where
    // one Change event triggers the next change, ad finem.
    function commit () {
        editorLoader.item.state = 'committing';
        var changes = editorLoader.item.getChanges();

        for (var i = 0; i < changes.length; i++) {
            var srvName = changes[i][0];
            var eName = srvName + "Changed";
            var nextChange = changes[i+1];

            // Subscribe to the *Changed event for this change,
            // and in the handler perform the next change.
            if (nextChange) {
                var handler = function (key, value, e, h) {
                    this[key] = value;
                    this[e].disconnect(h);
                }
                handler = handler.bind(
                    connection, nextChange[0], nextChange[1], eName, handler
                );
                connection[eName].connect(handler)
            }

            // If this is the last change, subscribe to its Change event
            // a handler that changes the UI's state to a done state.
            // Also, set the id to whatever the remote/gateway is, if any.
            if (i == changes.length - 1) {
                connection[eName].connect(function (editorItem, k, v) {
                    if (this[k] === v) {
                        editorItem.state = 'succeeded';
                        if (connection.remote) connection.id = connection.remote;
                        if (connection.gateway) connection.id = connection.gateway;
                    }
                }.bind(connection, editorLoader.item, srvName, changes[i][1]));
            }
        }

        // Start event chain.
        connection[changes[0][0]] = changes[0][1];
    }

    Component.onCompleted: {
        connection.updateSecrets()

        var props = {"connection": connection}
        switch (connection.type) {
        case 0: // Openvpn
            editorLoader.setSource("Openvpn/Editor.qml", props)
            break
        case 1: // Pptp
            editorLoader.setSource("Pptp/Editor.qml", props)
            break
        }
    }

    Component {
        id: fileDialogComponent
        DialogFile {
            id: fileDialog
        }
    }

    Loader {
        id: editorLoader
        anchors.left: parent.left
        anchors.right: parent.right
    }

    RowLayout {
        anchors { left: parent.left; right: parent.right }

        Button {
            objectName: "vpnEditorCancelButton"
            text: i18n.tr("Cancel")
            onClicked: {
                if (editor.isNew) {
                    connection.remove();
                }
                PopupUtils.close(editor)
            }
            Layout.fillWidth: true
        }

        Button {
            id: vpnEditorOkayButton
            objectName: "vpnEditorOkayButton"
            text: i18n.tr("OK")
            onClicked: editor.commit()
            Layout.fillWidth: true
            enabled: editorLoader.item.changed && editorLoader.item.valid

            Icon {
                height: parent.height - units.gu(1.5)
                width: parent.height - units.gu(1.5)
                anchors {
                    centerIn: parent
                }
                name: "tick"
                color: "green"
                visible: successIndicator.running
            }

            ActivityIndicator {
                id: okButtonIndicator
                running: false
                visible: running
                height: parent.height - units.gu(1.5)
                anchors {
                    centerIn: parent
                }
            }
        }
    }

    // Timer that shows a tick in the connect button once we have
    // successfully connected.
    Timer {
        id: successIndicator
        interval: 2000
        running: false
        repeat: false
        onTriggered: PopupUtils.close(editor)
    }

    // XXX: Workaround for lp:1546559.
    // Timer that makes sure our secrets are up to date. If this timer
    // does not run while we're committing changes, changes to fields
    // like “certPass” will never notify, and our loop will get stuck.
    Timer {
        id: secretUpdaterLoop
        interval: 500
        running: false
        repeat: true
        onTriggered: connection.updateSecrets()
    }
}
