/*
 * Copyright: 2013 - 2014 Canonical, Ltd
 *
 * This file is part of reminders
 *
 * reminders is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.3
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0
import Ubuntu.Components.Popups 1.0
import Evernote 0.1
import "../components"

Page {
    id: root
    objectName: 'notebooksPage'

    property bool narrowMode

    signal openNotebook(string notebookGuid)
    signal openSearch();

    onActiveChanged: {
        if (active) {
            notebooks.refresh();
        }
    }

    tools: ToolbarItems {
        ToolbarButton {
            action: Action {
                objectName: "addNotebookButton"
                text: i18n.tr("Add notebook")
                iconName: "add"
                onTriggered: {
                    contentColumn.newNotebook = true;
                }
            }
        }

        ToolbarButton {
            action: Action {
                text: i18n.tr("Search")
                iconName: "search"
                onTriggered: {
                    root.openSearch();
                }
            }
        }
    }

    Notebooks {
        id: notebooks
    }

    Column {
        id: contentColumn
        anchors.fill: parent
        property bool newNotebook: false

        states: [
            State {
                name: "newNotebook"; when: contentColumn.newNotebook
                PropertyChanges { target: newNotebookContainer; opacity: 1; height: newNotebookContainer.implicitHeight }
                PropertyChanges { target: buttonRow; opacity: 1; height: cancelButton.height + units.gu(4) }
            }
        ]

        Empty {
            id: newNotebookContainer
            height: 0
            visible: opacity > 0
            opacity: 0
            clip: true

            Behavior on height {
                UbuntuNumberAnimation {}
            }
            Behavior on opacity {
                UbuntuNumberAnimation {}
            }

            onVisibleChanged: {
                newNoteTitleTextField.forceActiveFocus();
            }

            TextField {
                id: newNoteTitleTextField
                objectName: "newNoteTitleTextField"
                anchors { left: parent.left; right: parent.right; margins: units.gu(2); verticalCenter: parent.verticalCenter }
            }
        }

        PulldownListView {
            id: notebooksListView
            objectName: "notebooksListView"
            model: notebooks
            anchors { left: parent.left; right: parent.right }
            height: parent.height - y - buttonRow.height - keyboardRect.height
            clip: true
            maximumFlickVelocity: units.gu(200)

            onRefreshed: {
                NotesStore.refreshNotebooks();
            }

            delegate: NotebooksDelegate {
                width: parent.width
                height: units.gu(10)
                triggerActionOnMouseRelease: true

                onItemClicked: {
                    print("selected notebook:", model.guid)
                    root.openNotebook(model.guid)
                }

                onDeleteNotebook: {
                    NotesStore.expungeNotebook(model.guid)
                }

                onSetAsDefault: {
                    NotesStore.setDefaultNotebook(model.guid)
                }

                onRenameNotebook: {
                    var popup = PopupUtils.open(renameNotebookDialogComponent, root, {name: model.name})
                    popup.accepted.connect(function(newName) {
                        notebooks.notebook(index).name = newName;
                        NotesStore.saveNotebook(model.guid);
                    })
                }
            }

            BouncingProgressBar {
                anchors.top: parent.top
                visible: notebooks.loading
            }

            Scrollbar {
                flickableItem: parent
            }
        }

        Item {
            id: buttonRow
            anchors { left: parent.left; right: parent.right; margins: units.gu(2) }
            height: 0
            visible: height > 0
            clip: true

            Behavior on height {
                UbuntuNumberAnimation {}
            }

            Button {
                id: cancelButton
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: i18n.tr("Cancel")
                onClicked: {
                    newNoteTitleTextField.text = "";
                    contentColumn.newNotebook = false
                }
            }
            Button {
                objectName: "saveButton"
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: i18n.tr("Save")
                enabled: newNoteTitleTextField.text.length > 0
                onClicked: {
                    NotesStore.createNotebook(newNoteTitleTextField.text);
                    newNoteTitleTextField.text = "";
                    contentColumn.newNotebook = false
                }
            }
        }
        Item {
            id: keyboardRect
            anchors { left: parent.left; right: parent.right }
            height: Qt.inputMethod.keyboardRectangle.height
        }
    }

    Component {
        id: renameNotebookDialogComponent
        Dialog {
            id: renameNotebookDialog
            title: i18n.tr("Rename notebook")
            text: i18n.tr("Enter a new name for notebook %1").arg(name)

            property string name

            signal accepted(string newName)

            TextField {
                id: nameTextField
                text: renameNotebookDialog.name
                placeholderText: i18n.tr("Name cannot be empty")
            }

            Button {
                text: i18n.tr("OK")
                enabled: nameTextField.text
                onClicked: {
                    renameNotebookDialog.accepted(nameTextField.text)
                    PopupUtils.close(renameNotebookDialog)
                }
            }
        }
    }
}
