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
import Evernote 0.1
import "../components"

Page {
    id: root
    property var note

    tools: ToolbarItems {
        ToolbarButton {
            text: "save"
            iconName: "select"
            onTriggered: {
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
        ToolbarSpacer {}

        ToolbarButton {
            text: "attach"
        }
        ToolbarButton {
            text: "camera"
            iconName: "camera-symbolic"
        }
        ToolbarButton {
            text: "rtf"
        }

    }

    Column {
        anchors.fill: parent
        anchors.margins: units.gu(2)
        spacing: units.gu(1)

        TextField {
            id: titleTextField
            text: root.note ? root.note.title : ""
            placeholderText: "Untitled"
            height: units.gu(5)
            anchors { left: parent.left; right: parent.right }
        }

        Divider {
            anchors { leftMargin: -units.gu(2); rightMargin: -units.gu(2) }
            height: units.gu(2)
        }

        OptionSelector {
            id: notebookSelector
            text: i18n.tr("Notebook")
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
}

