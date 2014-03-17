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
            text: i18n.tr("Accounts")
            iconName: "contacts-app-symbolic"
            visible: accounts.count > 1
            onTriggered: {
                openAccountPage(true);
            }
        }

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
        id: remindersListView
        anchors.fill: parent

        delegate: RemindersDelegate {
            note: notes.note(guid)

            Component.onCompleted: {
                if (index == remindersListView.count - 1) {
                    remindersLoadIndicator.running = false;
                }
            }
        }

        model: notes

        section.criteria: ViewSection.FullString
        section.property: "reminderTimeString"
        section.delegate: Standard {
            height: units.gu(3)
            text: section
        }

        ActivityIndicator {
            id: remindersLoadIndicator
            anchors.centerIn: parent
            running: true
            visible: running
        }
    }

}
