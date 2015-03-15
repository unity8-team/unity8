/*
 * Copyright: 2015 Canonical, Ltd
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
import Evernote 0.1
import "../components"

Page {
    id: root
    property alias note: conflictView.note
    title: i18n.tr("Conflicting changes")

    signal displayNote(var note)

    signal resolveConflict(bool keepLocal);

    NoteConflictView {
        id: conflictView
        anchors.fill: parent

        onDisplayNote: root.displayNote(note)
        onResolveConflict: root.resolveConflict(keepLocal)
    }
}
