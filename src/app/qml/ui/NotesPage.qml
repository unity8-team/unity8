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
import QtQuick.Layouts 1.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1
import Evernote 0.1
import "../components"

PageWithBottomEdge {
    id: root

    property var selectedNote: null
    property bool narrowMode

    property alias filter: notes.filterNotebookGuid

    // We enable bottomEdge only in narrowMode.
    // To avoid flashing when a notebook is loaded, we wait to have all notes
    // loaded, but only in notebook view (when a filter is set), not in notes
    // page, because there isn't he flashing.
    bottomEdgeLabelVisible: narrowMode && (!notes.filterNotebookGuid || !notes.loading)
    bottomEdgeTitle: i18n.tr("Add note")
    bottomEdgePageComponent: EditNotePage {
        isBottomEdge: true;
    }

    signal openSearch()
    signal editNote(var note)

    onActiveChanged: {
        if (active) {
            NotesStore.refreshNotes();
        }
    }

    tools: ToolbarItems {
        ToolbarButton {
            action: Action {
                visible: !narrowMode
                text: i18n.tr("Add note")
                iconName: "add"
                onTriggered: {
                    NotesStore.createNote("Untitled", filter);
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

        ToolbarButton {
            action: Action {
                text: i18n.tr("Refresh")
                iconName: "reload"
                onTriggered: {
                    NotesStore.refreshNotes();
                }
            }
        }

        ToolbarButton {
            action: Action {
                text: i18n.tr("Accounts")
                iconName: "contacts-app-symbolic"
                visible: accounts.count > 1
                onTriggered: {
                    openAccountPage(true);
                }
            }
        }

        ToolbarButton {
            action: Action {
                text: i18n.tr("Delete")
                iconName: "delete"
                visible: root.selectedNote !== null
                onTriggered: {
                    NotesStore.deleteNote(root.selectedNote.guid);
                }
            }
        }
        ToolbarButton {
            action: Action {
                text: root.selectedNote.reminder ? i18n.tr("Edit reminder") : i18n.tr("Set reminder")
                // TODO: use this instead when the toolkit switches from using the
                // ubuntu-mobile-icons theme to suru:
                //iconName: root.selectedNote.reminder ? "reminder" : "reminder-new"
                iconSource: root.selectedNote.reminder ?
                Qt.resolvedUrl("/usr/share/icons/suru/actions/scalable/reminder.svg") :
                Qt.resolvedUrl("/usr/share/icons/suru/actions/scalable/reminder-new.svg")
                visible: root.selectedNote !== null
                onTriggered: {
                    root.selectedNote.reminder = !root.selectedNote.reminder
                    NotesStore.saveNote(root.selectedNote.guid)
                }
            }
        }
        ToolbarButton {
            action: Action {
                text: i18n.tr("Edit")
                iconName: "edit"
                visible: root.selectedNote !== null
                onTriggered: {
                    print("should edit note")
                    root.editNote(root.selectedNote)
                }
            }
        }
    }

    Notes {
        id: notes
    }

    PulldownListView {
        id: notesListView
        objectName: "notespageListview"
        anchors { left: parent.left; right: parent.right }
        height: parent.height - y
        model: notes
        clip: true

        onRefreshed: {
            NotesStore.refreshNotes();
        }

        delegate: NotesDelegate {
            title: model.title
            creationDate: model.created
            content: model.plaintextContent
            resource: model.resourceUrls.length > 0 ? model.resourceUrls[0] : ""
            notebookColor: preferences.colorForNotebook(model.notebookGuid)

            Component.onCompleted: {
                if (!model.plaintextContent) {
                    NotesStore.refreshNoteContent(model.guid);
                }
            }

            onClicked: {
                root.selectedNote = NotesStore.note(guid);
            }
        }

        section.criteria: ViewSection.FullString
        section.property: "createdString"
        section.delegate: Empty {
            height: units.gu(5)
            showDivider: false
            RowLayout {
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: units.gu(2) }
                Label {
                    text: section
                    Layout.fillWidth: true
                }
                Label {
                    text: "(" + notes.sectionCount("createdString", section) + ")"
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
            visible: !notes.loading && (notes.error || notesListView.count == 0)
            width: parent.width - units.gu(4)
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: notes.error ? notes.error : i18n.tr("No notes available. You can create new notes using the \"Add note\" button.")
        }
    }
}
