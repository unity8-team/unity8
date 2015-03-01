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
import QtQuick.Layouts 1.0
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0
import Evernote 0.1
import "../components"

Page {
    id: root

    property var selectedNote: null

    signal openSearch();

    tools: ToolbarItems {
        ToolbarButton {
            action: Action {
                text: i18n.tr("Search")
                iconName: "search"
                onTriggered: {
                    root.openSearch();
                }
            }
        }

        ToolbarButton {
            action: Action {
                text: i18n.tr("Accounts")
                iconName: "contacts-app-symbolic"
                visible: allAccounts.count > 1
                onTriggered: {
                    openAccountPage(true);
                }
            }
        }
    }

    Notes {
        id: notes
        onlyReminders: true
    }

    Item {
        anchors.fill: parent
        ListView {
            id: remindersListView
            anchors { left: parent.left; right: parent.right }
            height: parent.height - y
            clip: true
            maximumFlickVelocity: units.gu(200)

            delegate: RemindersDelegate {
                width: remindersListView.width
                note: notes.note(guid)
                triggerActionOnMouseRelease: true

                onItemClicked: {
                    root.selectedNote = NotesStore.note(guid);
                }
            }

            model: notes

            section.criteria: ViewSection.FullString
            section.property: "reminderTimeString"
            section.delegate: Empty {
                height: units.gu(5)
                RowLayout {
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: units.gu(2) }
                    Label {
                        text: section
                        Layout.fillWidth: true
                    }
                    Label {
                        text: "(" + notes.sectionCount("reminderTimeString", section) + ")"
                    }
                }
            }

            ActivityIndicator {
                anchors.centerIn: parent
                running: notes.loading
                visible: running
            }
            Label {
                anchors.centerIn: parent
                visible: !notes.loading && (notes.error || remindersListView.count == 0)
                width: parent.width - units.gu(4)
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: notes.error ? notes.error :
                i18n.tr("No reminders available. You can create new reminders by setting a reminder when viewing a note.")
            }

            Scrollbar {
                flickableItem: parent
            }
        }
    }
}
