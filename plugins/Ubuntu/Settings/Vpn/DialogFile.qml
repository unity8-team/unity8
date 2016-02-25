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
import Ubuntu.Settings.Vpn 0.1
import Qt.labs.folderlistmodel 2.1

Dialog {
    objectName: "vpnDialogFile"
    id: dialog

    property string currentFilePath: ""

    signal accept(string path)
    signal reject

    function hideFunc() {
        DialogFileProperties.lastFolder = modelFs.folder
        currentFilePath = ""
    }

    function rejectFunc() {
        hideFunc()
        dialog.reject()
    }

    function acceptFunc() {
        var path = currentFilePath
        hideFunc()
        dialog.accept(path)
    }

    FolderListModel {
        id: modelFs
        showDirs: true
        showFiles: true
        showHidden: true
        showDirsFirst: true
        showDotAndDotDot: false
        showOnlyReadable: false
        sortField: FolderListModel.Name

        folder: (DialogFileProperties.lastFolder === "")? "file:///home/" : DialogFileProperties.lastFolder
    }

    ColumnLayout {
        height: root.height - units.gu(10)
        spacing: units.gu(1)

        Flow {
            spacing: units.gu(1)
            Layout.fillWidth: true

            Repeater {
                model: {
                    var ret = []
                    var path = "file:///"
                    ret.push({ "name" : "/", "url" : path })
                    var tmp = modelFs.folder.toString().replace("file:///", "").split("/")
                    for (var idx = 0; idx < tmp.length; idx++) {
                        var name = tmp[idx] + "/"
                        if (name !== "/") {
                            path += name
                            ret.push({ "name" : name, "url" : path })
                        }
                    }
                    return ret
                }
                delegate: Row {
                    spacing: units.gu(0.7)

                    property bool isCurrent : Positioner.isLastItem

                    Rectangle {
                        width: units.gu(0.7)
                        height: width
                        color: "gray"
                        rotation: 45
                        visible: (model.index > 0)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Label {
                        objectName: "vpnFilePathItem_" + model.modelData["name"]
                        text: model.modelData["name"]
                        font.weight: (isCurrent ? Font.Bold : Font.Normal)
                        font.underline: hoverDetector.containsMouse
                        color: "darkblue"
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            id: hoverDetector
                            enabled: !isCurrent
                            hoverEnabled: true
                            anchors.fill: parent
                            onClicked: modelFs.folder = model.modelData["url"]
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            border {
                width: 1
                color: "lightgrey"
            }

            ListView {
                objectName: "vpnFileList"
                anchors.fill: parent
                anchors.margins: 1
                clip: true
                model: modelFs

                delegate: ListItems.Standard {
                    objectName: "vpnFileItem_" + model.fileName
                    text: model.fileName
                    iconFrame: false
                    iconName: model.fileIsDir ? "folder" : "empty"

                    selected: (model.filePath === currentFilePath)

                    onClicked: {
                        if (model.fileIsDir) {
                            modelFs.folder = model.fileURL
                        } else {
                            currentFilePath = model.filePath
                        }
                    }
                }
            }
        }

        RowLayout {
            spacing: units.gu(1)
            Layout.fillWidth: true

            Button {
                objectName: "vpnFileCancel"
                Layout.fillWidth: true
                text: i18n.tr("Cancel")
                onClicked: rejectFunc()
                color: UbuntuColors.red
            }

            Button {
                objectName: "vpnFileAccept"
                Layout.fillWidth: true
                enabled: currentFilePath !== ""
                text: i18n.tr("Accept")
                onClicked: acceptFunc()
                color: UbuntuColors.green
            }
        }
    }
}
