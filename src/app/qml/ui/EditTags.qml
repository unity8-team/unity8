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
import Ubuntu.Components.ListItems 1.0
import Evernote 0.1
import "../components"

Page {
    id: root

    property bool narrowMode
    property var note
    property variant tagGuids: note.tagGuids

    signal newTagSelected(var guid);

    title: i18n.tr("Modify tags")

    head.backAction: Action {
        iconName: "back"
        text: i18n.tr("Back")
        onTriggered: {
            note.tagGuids = tagGuids;
            pagestack.pop();
        }
    }

    Tags {
        id: tags
    }

    ColumnLayout {
        anchors.fill: parent

        TextField {
            width: parent.width - units.gu(2)
            Layout.alignment: Qt.AlignHCenter

            Keys.onReturnPressed: {
                // Check if the tag exists
                for (var i=0; i < tags.count; i++) {
                    var tag = tags.tag(i);
                    if (tag.name == text) {
                        // The tag exists, check if is already selected: if it is,
                        // do nothing, otherwise add to tags of the note
                        if (note.tagGuids.indexOf(tag.guid) === -1) {
                            tagGuids.push(tag.guid);
                            // TODO: select in optionSelector
                        }
                        return;
                    }
                }

                // TODO: create a tag and add it to the list
            }
        }

        OptionSelector {
            id: optionSelector
            Layout.fillHeight: true
            currentlyExpanded: true
            multiSelection: true

            width: parent.width - units.gu(2)
            Layout.alignment: Qt.AlignHCenter

            model: tags

            delegate: OptionSelectorDelegate {
                text: model.name
                selected: root.note.tagGuids.indexOf(model.guid) !== -1

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        if (selected) {
                            var index = root.tagGuids.indexOf(model.guid);
                            root.tagGuids.splice(index, 1);
                        }
                        else {
                            root.tagGuids.push(model.guid);
                        }
                        selected = !selected;
                    }
                }
            }
        }
    }
}
