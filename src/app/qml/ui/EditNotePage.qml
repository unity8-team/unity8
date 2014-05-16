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
    property alias note: editNoteView.note

    signal exitEditMode(var note)

    tools: ToolbarItems {
        locked: true
        opened: false
    }

    EditNoteView {
        id: editNoteView
        anchors.fill: parent

        onExitEditMode: root.exitEditMode(note);
    }
}

