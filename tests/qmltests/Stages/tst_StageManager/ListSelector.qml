/*
 * Copyright 2013 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Application 0.1
import Ubuntu.Components 0.1

Rectangle {
    id: root
    color: "#ccffffff"
    height: childrenRect.height

    property alias list: repeater.model
    signal activated(string entry)
    signal deactivated(string entry)

    function activate(entry) {
        lister.changeEntry(entry, true);
    }

    function deactivate(entry) {
        lister.changeEntry(entry, false);
    }

    function deactivateAll() {
        for (var i=0; i<list.length; i++) {
            lister.changeEntry(list[i], false);
        }
    }

    Flow {
        id: lister
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        function changeEntry(entry, setting) {
            for (var i=0; i<lister.children.length; i++) {
                var child = lister.children[i];
                if (child === lister) continue;
                if (child.label == entry) {
                    if (child.checked == setting) {
                        if (setting) root.activated(child.label); //ensure we fire activated again
                    } else {
                        child.checked = setting;
                    }
                    break;
                }
            }
        }
        Repeater {
            id: repeater
            delegate: entry
        }

        Component {
            id: entry

            Row {
                height: units.gu(5)
                width: units.gu(20)

                property alias checked: checkbox.checked
                property string label: modelData

                CheckBox {
                    id: checkbox
                    onCheckedChanged: {
                        if (checked) {
                            activated(modelData)
                        } else {
                            deactivated(modelData)
                        }
                    }
                }
                Button {
                    text: parent.label
                    width: parent.width - checkbox.width
                    anchors.verticalCenter: checkbox.verticalCenter
                    enabled: checkbox.checked
                    onClicked: activated(modelData)
                }
            }
        }
    }
}
