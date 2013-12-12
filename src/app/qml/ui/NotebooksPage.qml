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

Page {
    id: notebooksPage

    onActiveChanged: {
        if (active) {
            notebooks.refresh();
        }
    }

    tools: ToolbarItems {
        ToolbarButton {
            text: "add notebook"
            enabled: notes.filterNotebookGuid.length > 0
            onTriggered: {
                NotesStore.createNotebook("new notebook");
            }
        }
    }

    Notebooks {
        id: notebooks
    }

    ListView {
        anchors.fill: parent
        model: notebooks

        delegate: Standard {
            text: name

            onClicked: {
                pagestack.push(Qt.resolvedUrl("NotesPage.qml"), {title: name, filter: guid});
            }
        }
    }
}
