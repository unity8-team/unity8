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

Page {
    id: editor
    objectName: "vpnEditorDialog"
    title: i18n.tr("Set up VPN")

    property var connection

    // If isNew, we delete it on cancel.
    property var isNew

    signal typeChanged(var connection, int type)

    function commit () {
        editorLoader.item.state = 'committing';
        var changes = editorLoader.item.getChanges();

        for (var i = 0; i < changes.length; i++) {
            var key = changes[i][0];
            var value = changes[i][1];
            connection[key] = value;
            if (key == "gateway" || key == "remote") connection.id = value;
        }
        editorLoader.item.state = 'succeeded';
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

    head {
        backAction: Action { visible: false }
    }

    Component {
        id: fileDialogComponent
        DialogFile {
            id: fileDialog
        }
    }

    Flickable {
        id: scrollWidget
        anchors {
            fill: parent
            margins: units.gu(2)
        }
        contentHeight: contentItem.childrenRect.height
        boundsBehavior: (contentHeight > editor.height) ? Flickable.DragAndOvershootBounds : Flickable.StopAtBounds

        Column {
            anchors { left: parent.left; right: parent.right }
            spacing: units.gu(2)

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
                        pageStack.pop();
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
        }
    }

    // Timer that shows a tick in the connect button once we have
    // successfully connected.
    Timer {
        id: successIndicator
        interval: 2000
        running: false
        repeat: false
        onTriggered: pageStack.pop()
    }
}
