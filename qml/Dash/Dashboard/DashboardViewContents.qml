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

    property alias model: journal.model
    property bool editMode: false
    property int columnCount: 3
    property int contentSpacing

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
        keys: ["unity8-dashboard"]
        
        onDropped: {
            var fromIndex = drag.source.visualIndex;
            print("DROP from:", drop.source, ", index:", fromIndex);
            
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
                journal.view.move(fromIndex, toIndex); // this refreshes the view as well
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
            width: parent.columnWidth
            
            onClose: {
                print("Closing index:", index)
                contents.model.remove(index, 1);
            }
            onItemDragging: autoscroller.autoscroll(dragging, dragItem)
        }
    }
}
