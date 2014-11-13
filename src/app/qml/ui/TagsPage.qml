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
import Evernote 0.1
import "../components"

Page {
    id: root
    objectName: 'tagsPage'

    property bool narrowMode

    signal openTaggedNotes(string tagGuid)

    onActiveChanged: {
        if (active) {
            // We really want to refresh notes, not tags here.
            // If a new tag appears on a note, the plugin will automatically update tags
            // but just refreshing tags alone wouldn't update the tag count because we
            // still wouldn't know on which notes the tags are attached.
            NotesStore.refreshNotes();
            // Lets refresh tags nevertheless for the unlikely case that the user added
            // a tag alone without attaching it to a note from another app (You can't do
            // that in the webinterface)
            tags.refresh();
        }
    }

    tools: ToolbarItems {
        ToolbarButton {
            action: Action {
                text: i18n.tr("Search")
                iconName: "search"
                onTriggered: {
                    pagestack.push(Qt.resolvedUrl("SearchNotesPage.qml"))
                }
            }
        }

        ToolbarButton {
            action: Action {
                text: i18n.tr("Refresh")
                iconName: "reload"
                onTriggered: {
                    NotesStore.refreshNotes();
                    tags.refresh();
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
    }

    Tags {
        id: tags
    }

    Column {
        id: contentColumn
        anchors.fill: parent
        property bool newNotebook: false

        PulldownListView {
            id: tagsListView
            objectName: "tagsListView"
            model: tags
            anchors { left: parent.left; right: parent.right }
            height: parent.height - y - keyboardRect.height
            clip: true

            onRefreshed: {
                NotesStore.refreshTags();
            }

            delegate: TagsDelegate {
                onClicked: {
                    print("selected tag:", model.guid)
                    root.openTaggedNotes(model.guid)
                }
            }

            ActivityIndicator {
                anchors.centerIn: parent
                running: tags.loading
                visible: running
            }

            Label {
                anchors.centerIn: parent
                width: parent.width - units.gu(4)
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                visible: !tags.loading && tags.error
                text: tags.error
            }

            Scrollbar {
                flickableItem: parent
            }
        }

        Label {
            anchors.centerIn: parent
            visible: !tags.loading && (tags.error || tagsListView.count == 0)
            width: parent.width - units.gu(4)
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: tags.error ? tags.error : i18n.tr("No tags available. You can tag notes while viewing them.")
        }

        Item {
            id: keyboardRect
            anchors { left: parent.left; right: parent.right }
            height: Qt.inputMethod.keyboardRectangle.height
        }
    }
}
