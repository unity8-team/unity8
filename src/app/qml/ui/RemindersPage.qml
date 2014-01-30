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
    id: remindersPage

    tools: ToolbarItems {
        ToolbarButton {
            text: i18n.tr("Search")
            iconName: "search"
            onTriggered: {
                pagestack.push(Qt.resolvedUrl("SearchNotesPage.qml"))
            }
        }

        ToolbarSpacer { }

        ToolbarButton {
            text: i18n.tr("Add reminder")
            iconName: "add"
            onTriggered: {
            }
        }
    }

    Notes {
        id: notes
        onlyReminders: true
    }

    ListView {

        anchors.fill: parent

        delegate: Subtitled {
            text: '<b>Name:</b> ' + model.title
            subText: '<b>Date:</b> ' + Qt.formatDateTime(model.created) +
                     (model.reminderDone ? " - <b>Done:</b> " + Qt.formatDate(model.reminderDoneTime) : "")
        }

        model: notes
    }

}
