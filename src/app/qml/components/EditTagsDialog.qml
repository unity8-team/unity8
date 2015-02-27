/*
 * Copyright: 2014 Canonical, Ltd
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
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.Components.ListItems 1.0
import Evernote 0.1

Dialog {
    id: root

    property var note
    property int pageHeight

    signal done();

    Tags {
        id: tags
    }

    RowLayout {
        Layout.preferredWidth: parent.width - units.gu(2)
        Layout.alignment: Qt.AlignHCenter

        TextField {
            id: textField
            Layout.fillWidth: true
            placeholderText: i18n.tr("Create a new tag")

            onAccepted: accept();

            function accept() {
                var tagName = text;
                text = '';

                // Check if the tag exists
                for (var i=0; i < tags.count; i++) {
                    var tag = tags.tag(i);
                    if (tag.name == tagName) {
                        // The tag exists, check if is already selected: if it is,
                        // do nothing, otherwise add to tags of the note
                        if (note.tagGuids.indexOf(tag.guid) === -1) {
                            note.tagGuids.push(tag.guid);
                        }
                        return;
                    }
                }

                var newTag = NotesStore.createTag(tagName);
                print("tag created", newTag.name, "appending to note");
                note.tagGuids.push(newTag.guid)
            }
        }

        Button {
            text: i18n.tr("Create tag")
            color: UbuntuColors.orange
            enabled: textField.text.replace(/\s+/g, '') !== ''; // Not only whitespaces!
            onClicked: textField.accept()
        }
    }

    OptionSelector {
        id: optionSelector

        Layout.preferredWidth: parent.width - units.gu(2)
        Layout.alignment: Qt.AlignHCenter

        currentlyExpanded: true
        multiSelection: true

        containerHeight: Math.min(root.pageHeight - textField.height - closeButton.height - units.gu(12), tags.count * itemHeight)

        model: tags

        delegate: OptionSelectorDelegate {
            text: model.name
            selected: root.note ? root.note.tagGuids.indexOf(model.guid) !== -1 : false

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    if (selected) {
                        var index = root.note.tagGuids.indexOf(model.guid);
                        root.note.tagGuids.splice(index, 1);
                    }
                    else {
                        root.note.tagGuids.push(model.guid);
                    }
                }
            }
        }
    }

    Button {
        id: closeButton
        Layout.preferredWidth: parent.width - units.gu(2)
        Layout.alignment: Qt.AlignHCenter

        color: UbuntuColors.orange

        text: i18n.tr("Done")

        onClicked: {
            root.done();
            PopupUtils.close(root)
        }
    }
}
