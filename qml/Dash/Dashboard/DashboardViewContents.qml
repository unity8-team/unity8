/*
 * Copyright (C) 2017 Canonical, Ltd.
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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Utils 0.1
import "../../Components"
import ".."
import "../../Components/flickableUtils.js" as FlickableUtilsJS

ScrollView {
    id: contents
    objectName: "DashboardViewContents"

    // write API
    property alias model: journal.model
    property bool editMode: false
    property int columnCount: 3
    property int contentSpacing

    // read-write API
    property var indexesToClose: []

    flickableItem {
        flickableDirection: Flickable.VerticalFlick
        flickDeceleration: FlickableUtilsJS.getFlickDeceleration(units.gridUnit)
        maximumFlickVelocity: FlickableUtilsJS.getMaximumFlickVelocity(units.gridUnit)
        boundsBehavior: Flickable.StopAtBounds
    }
    horizontalScrollbar.enabled: false

    Autoscroller {
        id: autoscroller
        flickable: contents.flickableItem
    }

    DropArea {
        id: dropArea
        anchors.fill: parent
        keys: "unity8-dashboard"

        onDropped: {
            var fromIndex = drop.source.visualIndex;
            print("Drop from:", drop.source, ", index:", fromIndex);
            
            function matchDelegate(obj) { return String(obj.objectName).indexOf("dashboardDelegate") >= 0 &&
                                          obj.objectName !== drag.source.objectName; }
            var delegateAtCenter = Functions.itemAt(journal.view, drop.x, drop.y, matchDelegate);
            
            if (!delegateAtCenter) {
                print("Invalid drop, bailing out");
                journal.view.relayout();
                return;
            }
            
            var toIndex = delegateAtCenter.visualIndex;
            print("Dropped on", delegateAtCenter, ", index:", toIndex);
            
            if (delegateAtCenter) {
                journal.model.move(fromIndex, toIndex, 1);

                Array.prototype.move = function (old_index, new_index) {
                    if (new_index >= this.length) {
                        var k = new_index - this.length;
                        while ((k--) + 1) {
                            this.push(undefined);
                        }
                    }
                    this.splice(new_index, 0, this.splice(old_index, 1)[0]);
                    return this; // for testing purposes
                };
                indexesToClose.move(fromIndex, toIndex);

                drop.acceptProposedAction();
            }
        }
    }

    ResponsiveVerticalJournal {
        id: journal
        width: contents.width
        
        rowSpacing: contents.contentSpacing
        minimumColumnSpacing: contents.contentSpacing
        columnWidth: (contents.width - root.leftMargin*2 - contents.verticalScrollbar.width) / contents.columnCount

        delegate: DashboardDelegate {
            editMode: contents.editMode
            shouldClose: indexesToClose.indexOf(index) !== -1
            width: parent.columnWidth
            height: model.height

            onClose: {
                print("Closing index:", index);
                indexesToClose.push(index);
                shouldClose = true;
            }
            onUndoClose: {
                print("Undoing close:", index);
                indexesToClose.splice(indexesToClose.indexOf(index), 1);
                shouldClose = false;
            }

            onItemDragging: autoscroller.autoscroll(dragging, dragItem)
        }
    }
}
