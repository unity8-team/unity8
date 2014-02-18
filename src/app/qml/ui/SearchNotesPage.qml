/*
 * Copyright: 2013 Canonical, Ltd
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

import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1
import Evernote 0.1
import "../components"

Page {
    id: root

    signal noteSelected(var note)

    Column {
        anchors { fill: parent; topMargin: units.gu(2); bottomMargin: units.gu(2) }
        spacing: units.gu(2)

        Row {
            anchors { left: parent.left; right: parent.right; margins: units.gu(2) }
            spacing: units.gu(1)

            TextField {
                id: searchField
                width: parent.width - searchButton.width - parent.spacing
                anchors.verticalCenter: parent.verticalCenter

                primaryItem: Icon {
                    height: searchField.height - units.gu(1)
                    width: height
                    name: "search"
                }

                onAccepted: {
                    NotesStore.findNotes(searchField.text + "*")
                }
            }
            Button {
                id: searchButton
                height: searchField.height
                text: i18n.tr("Search")
                onClicked: {
                    NotesStore.findNotes(searchField.text + "*")
                }
            }
        }

        ListView {
            anchors { left: parent.left; right: parent.right }
            height: parent.height - y
            clip: true

            model: Notes {
                onlySearchResults: true
            }

            delegate: NotesDelegate {
                title: model.title
                creationDate: model.created
                content: model.plaintextContent

                onClicked: {
                    root.noteSelected(NotesStore.note(guid))
                }
            }
        }

    }
}
