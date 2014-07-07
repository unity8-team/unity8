/*
 * Copyright (C) 2013 Canonical, Ltd.
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
import "../Components"

DashRenderer {
    id: root

    height: gridView.height

    readonly property int collapsedRowCount: cardTool && cardTool.template && cardTool.template["collapsed-rows"] || 2
    property int shownRowCount: Math.min(collapsedRowCount, gridView.rowCount)

    canGrow: shownRowCount < gridView.rowCount
    canShrink: shownRowCount > collapsedRowCount

    function grow() {
        shownRowCount = gridView.rowCount
    }

    function shrink() {
        shownRowCount = collapsedRowCount
    }

    function setFilter(filter, animate) {
        filterGrid.setFilter(filter, animate)
    }

    ResponsiveGridView {
        id: gridView
        width: root.width
        height: contentHeightForRows(shownRowCount)
        interactive: false
        minimumHorizontalSpacing: units.gu(1)
        delegateWidth: cardTool.cardWidth
        delegateHeight: cardTool.cardHeight
        verticalSpacing: units.gu(1)
        model: root.model
        //highlightIndex: root.highlightIndex
        //delegateCreationBegin: root.delegateCreationBegin
        //delegateCreationEnd: root.delegateCreationEnd
        delegate: Item {
            width: gridView.cellWidth
            height: gridView.cellHeight
            Loader {
                id: loader
                sourceComponent: cardTool.cardComponent
                anchors.horizontalCenter: parent.horizontalCenter
                onLoaded: {
                    item.objectName = "delegate" + index;
                    item.width = Qt.binding(function() { return cardTool.cardWidth; });
                    item.height = Qt.binding(function() { return cardTool.cardHeight; });
                    item.fixedArtShapeSize = Qt.binding(function() { return cardTool.artShapeSize; });
                    item.cardData = Qt.binding(function() { return model; });
                    item.template = Qt.binding(function() { return cardTool.template; });
                    item.components = Qt.binding(function() { return cardTool.components; });
                    item.headerAlignment = Qt.binding(function() { return cardTool.headerAlignment; });
                }
                Connections {
                    target: loader.item
                    onClicked: root.clicked(index, result)
                    onPressAndHold: root.pressAndHold(index)
                }
            }
        }
    }
}
