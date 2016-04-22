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
import Ubuntu.Components.Themes 1.3

Page {
    id: editor
    objectName: "vpnEditor"
    title: i18n.dtr("ubuntu-settings-components", "Set up VPN")

    property var connection

    // If isNew, we delete it on cancel.
    property var isNew

    signal typeChanged(var connection, int type)
    signal reconnectionPrompt()

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

    function render () {
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

    Component.onCompleted: render()

    header: PageHeader {
        title: editor.title
        flickable: scrollWidget
        leadingActionBar.actions: []
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
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: actionButtons.top
            margins: units.gu(2)
        }
        contentHeight: contentItem.childrenRect.height
        boundsBehavior: (contentHeight > editor.height) ? Flickable.DragAndOvershootBounds : Flickable.StopAtBounds

        Column {
            anchors { left: parent.left; right: parent.right }
            spacing: units.gu(2)

            Loader {
                id: editorLoader
                objectName: "editorLoader"
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: actionButtons.top
        }
        height: units.gu(0.1)
        color: Qt.rgba(0,0,0,0.2)
    }

    Rectangle {
        color: theme.palette.normal.background
        id: actionButtons
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: units.gu(6)

        RowLayout {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: units.gu(2)
            }
            spacing: units.gu(2)

            Button {
                objectName: "vpnEditorCancelButton"
                text: i18n.dtr("ubuntu-settings-components", "Cancel")
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
                text: i18n.dtr("ubuntu-settings-components", "OK")
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
                    objectName: "okButtonIndicator"
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

    // Timer that shows a tick in the connect button once we have
    // successfully connected.
    Timer {
        id: successIndicator
        objectName: "successIndicator"
        interval: 2000
        running: false
        repeat: false
        onTriggered: {
            if (connection.active) {
                editor.reconnectionPrompt();
            }
            pageStack.pop();
        }
    }
}
