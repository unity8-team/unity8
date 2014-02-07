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
import Ubuntu.Components 0.1
import Unity 0.2
import "../Components"
import "Previews" as Previews

Item {
    property OpenEffect openEffect: null
    property ScopeListView categoryView: null
    property Scope scope: null

    property alias open: previewListView.open
    property alias onScreen: previewListView.onScreen
    property alias categoryId: previewListView.categoryId
    property alias categoryDelegate: previewListView.categoryDelegate
    property alias model: previewListView.model
    property alias currentIndex: previewListView.currentIndex
    property alias currentItem: previewListView.currentItem

    Image {
        objectName: "pointerArrow"
        anchors {
            top: previewListView.bottom
            left: parent.left
            leftMargin: previewListView.categoryDelegate !== undefined && previewListView.categoryDelegate.currentItem ?
                            previewListView.categoryDelegate.currentItem.center + (-width + margins) / 2 : 0

            Behavior on leftMargin {
                SmoothedAnimation {
                    duration: UbuntuAnimation.FastDuration
                }
            }
        }
        height: units.gu(1)
        width: units.gu(2)
        property int margins: previewListView.categoryDelegate ? previewListView.categoryDelegate.margins : 0
        opacity: previewListView.open ? .5 : 0

        source: "graphics/tooltip_arrow.png"
    }

    ListView  {
        id: previewListView
        objectName: "previewListView"
        height: openEffect.bottomGapPx - openEffect.topGapPx
        anchors {
            top: parent.top
            topMargin: openEffect.topGapPx
            left: parent.left
            right: parent.right
        }
        orientation: ListView.Horizontal
        highlightRangeMode: ListView.StrictlyEnforceRange
        snapMode: ListView.SnapOneItem
        boundsBehavior: Flickable.DragAndOvershootBounds
        highlightMoveDuration: 250
        flickDeceleration: units.gu(625)
        maximumFlickVelocity: width * 5
        cacheBuffer: 0

        // To be set before opening the preview
        property string categoryId: ""
        property var categoryDelegate

        // because the ListView is built asynchronous, setting the
        // currentIndex directly won't work. We need to refresh it
        // when the first preview is ready to be displayed.
        property bool init: true

        onCurrentIndexChanged: {
            if (currentIndex < 0) return;
            var row = Math.floor(currentIndex / categoryDelegate.columns);
            if (categoryDelegate.collapsedRowCount <= row) {
                categoryView.expandedCategoryId = categoryId
            }

            if (open) {
                categoryDelegate.highlightIndex = currentIndex
            }

            if (model !== undefined) {
                var item = model.get(currentIndex)
                previewListView.currentItem.previewModel = scope.preview(item.result)
            }

            // Adjust contentY in case we need to change to it to show the next row
            if (categoryDelegate.rows > 1) {
                var itemY = categoryView.contentItem.mapFromItem(categoryDelegate.currentItem).y;

                // Find new contentY and effect.postionPx
                var newContentY = itemY - openEffect.positionPx - categoryDelegate.verticalSpacing;

                // Make sure the item is not covered by a header. Move the effect split down if necessary
                var headerHeight = pageHeader.height + categoryView.stickyHeaderHeight;
                var effectAdjust = Math.max(openEffect.positionPx, headerHeight);

                // Make sure we don't overscroll the listview. If yes, adjust effect position
                if (newContentY < 0) {
                    effectAdjust += newContentY;
                    newContentY = 0;
                }
                if (newContentY > Math.max(0, categoryView.contentHeight - categoryView.height)) {
                    effectAdjust += -(categoryView.contentHeight - categoryView.height) + newContentY
                    newContentY = categoryView.contentHeight - categoryView.height;
                }

                openEffect.positionPx = effectAdjust;
                categoryView.contentY = newContentY;
            }
        }

        property bool open: false
        property bool onScreen: false

        onOpenChanged: {
            if (open) {
                onScreen = true;
                categoryDelegate.highlightIndex = currentIndex;
                pageHeader.unfocus();
            } else {
                // Cancel any pending preview requests or actions
                if (previewListView.currentItem.previewData !== undefined) {
                    previewListView.currentItem.previewData.cancelAction();
                }
                scope.cancelActivation();
                model = undefined;
                categoryView.correctExpandedCategory();
                categoryDelegate.highlightIndex = -1;
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, .3)
            z: -1
        }

        delegate: Previews.Preview {
            id: preview
            objectName: "preview" + index
            height: previewListView.height
            width: previewListView.width

            isCurrent: ListView.isCurrentItem

            onPreviewModelChanged: preview.opacity = 0;
            onReadyChanged: if (ready) fadeIn.start()
//            onClose: {
//                previewListView.open = false
//            }

            PropertyAnimation {
                id: fadeIn
                target: preview
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: UbuntuAnimation.BriskDuration
            }

            ActivityIndicator {
                anchors.centerIn: parent
                running: visible
            }
        }
    }
}
