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
import Ubuntu.Components.Popups 1.0
import Evernote 0.1
import "../components"

Page {
    id: root
    objectName: 'tagsPage'

    property bool narrowMode

    signal openTaggedNotes(string tagGuid)
    signal openSearch();

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
                    root.openSearch();
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
            maximumFlickVelocity: units.gu(200)

            onRefreshed: {
                NotesStore.refreshTags();
            }

            delegate: TagsDelegate {
                width: parent.width
                height: units.gu(10)
                triggerActionOnMouseRelease: true

                onItemClicked: {
                    print("selected tag:", model.guid)
                    root.openTaggedNotes(model.guid)
                }
                onDeleteTag: {
                    NotesStore.expungeTag(model.guid);
                }

                onRenameTag: {
                    var popup = PopupUtils.open(renameTagDialogComponent, root, {name: model.name})
                    popup.accepted.connect(function(newName) {
                        tags.tag(index).name = newName;
                        NotesStore.saveTag(model.guid);
                    })
                }
            }

            ActivityIndicator {
                anchors.centerIn: parent
                running: tags.loading
                visible: running
            }

            Scrollbar {
                flickableItem: parent
            }
        }

        Item {
            id: keyboardRect
            anchors { left: parent.left; right: parent.right }
            height: Qt.inputMethod.keyboardRectangle.height
        }
    }

    Label {
        anchors.centerIn: parent
        visible: !tags.loading && tagsListView.count == 0
        width: parent.width - units.gu(4)
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        text: i18n.tr("No tags available. You can tag notes while viewing them.")
    }

    Component {
        id: renameTagDialogComponent
        Dialog {
            id: renameTagDialog
            title: i18n.tr("Rename tag")
            text: i18n.tr("Enter a new name for tag %1").arg(name)

            property string name

            signal accepted(string newName)

            TextField {
                id: nameTextField
                text: renameTagDialog.name
                placeholderText: i18n.tr("Name cannot be empty")
            }

            Button {
                text: i18n.tr("OK")
                enabled: nameTextField.text
                onClicked: {
                    renameTagDialog.accepted(nameTextField.text)
                    PopupUtils.close(renameTagDialog)
                }
            }
        }
    }
}
