/*
 * Copyright: 2013 Canonical, Ltd
 *
 * This file is part of reminders-app
 *
 * reminders-app is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1
import Ubuntu.Content 0.1
import Evernote 0.1
import "../components"

Page {
    id: root
    property var note

    tools: ToolbarItems {
        locked: true
        opened: false
    }

    QtObject {
        id: priv
        property int insertPosition
        property var activeTransfer
    }

    ContentImportHint {
        id: importHint
        anchors.fill: parent
        activeTransfer: root.activeTransfer
    }
    Connections {
         target: priv.activeTransfer ? priv.activeTransfer : null
         onStateChanged: {
             if (priv.activeTransfer.state === ContentTransfer.Charged) {
                 print("attaching", priv.activeTransfer.items[0].url.toString())
                 note.attachFile(priv.insertPosition, priv.activeTransfer.items[0].url.toString())
             }
         }
     }

    Column {
        anchors { left: parent.left; top: parent.top; right: parent.right; bottom: toolbox.top }
        anchors.margins: units.gu(2)
        spacing: units.gu(1)

        Row {
            anchors { left: parent.left; right: parent.right }
            height: units.gu(5)
            spacing: units.gu(2)
            Icon {
                id: backIcon
                name: "back"
                height: units.gu(3)
                width: height
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        pagestack.pop();
                    }
                }
            }

            TextField {
                id: titleTextField
                text: root.note ? root.note.title : ""
                placeholderText: i18n.tr("Untitled")
                height: units.gu(5)
                width: parent.width - (backIcon.width + parent.spacing) * 2
            }
            Icon {
                name: "save"
                height: units.gu(3)
                width: height
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var title = titleTextField.text ? titleTextField.text : i18n.tr("Untitled");
                        var notebookGuid = notebookSelector.selectedGuid;
                        var text = noteTextArea.text;

                        if (note) {
                            note.title = titleTextField.text
                            note.notebookGuid = notebookSelector.selectedGuid
                            note.richTextContent = noteTextArea.text
                            NotesStore.saveNote(note.guid);
                        } else {
                            NotesStore.createNote(title, notebookGuid, text);
                        }

                        pagestack.pop();
                    }
                }
            }
        }

        Divider {
            anchors { leftMargin: -units.gu(2); rightMargin: -units.gu(2) }
            height: units.gu(2)
        }

        OptionSelector {
            id: notebookSelector
            model: Notebooks {}
            property string selectedGuid: model.notebook(selectedIndex).guid

            delegate: OptionSelectorDelegate {
                text: model.name
            }
        }

        TextArea {
            id: noteTextArea
            anchors { left: parent.left; right: parent.right }
            height: parent.height - y
            highlighted: true

            textFormat: TextEdit.RichText
            text: root.note ? root.note.richTextContent : ""
        }
    }

    Rectangle {
        id: toolbox
        anchors { left: parent.left; right: parent.right; bottom: keyboardRect.top }
        height: units.gu(6)
        color: "white"

        Icon {
            name: "import-image"
            height: units.gu(3)
            width: height
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.margins: units.gu(2)
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    priv.insertPosition = noteTextArea.cursorPosition;
                    note.richTextContent = noteTextArea.text;

                    priv.activeTransfer = ContentHub.importContent(ContentType.Pictures);
                    priv.activeTransfer.selectionType = ContentTransfer.Single;
                    priv.activeTransfer.start();
                }
            }
        }

        Icon {
            name: "camera-symbolic"
            height: units.gu(3)
            width: height
            anchors.centerIn: parent
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    pagestack.push(Qt.resolvedUrl("CameraPage.qml"), {note: root.note, position: priv.insertPosition})
                }
            }
        }

        Icon {
            name: "edit"
            height: units.gu(3)
            width: height
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.margins: units.gu(2)
            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }
        }


    }

    Item {
        id: keyboardRect
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: Qt.inputMethod.keyboardRectangle.height
    }
}

