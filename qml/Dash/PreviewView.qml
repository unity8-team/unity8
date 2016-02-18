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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Unity 0.2
import "../Components"
import "Previews" as Previews

Item {
    id: root

    property bool open: false
    property int initialIndex: -1
    property var initialIndexPreviewStack: null
    property var scope: null
    property var scopeStyle: null
    property string categoryId
    property bool usedInitialIndex: false

    property alias showSignatureLine: header.showSignatureLine

    property var model
    property alias currentIndex: previewLoader.index
    property alias currentItem: previewLoader.item

    readonly property bool processing: currentItem && (!currentItem.previewModel.loaded
                                                       || currentItem.previewModel.processingAction)

    signal backClicked()

    DashPageHeader {
        id: header
        objectName: "pageHeader"
        width: parent.width
        title: root.scope ? root.scope.name : ""
        showBackButton: true
        searchEntryEnabled: false
        scopeStyle: root.scopeStyle

        onBackClicked: root.backClicked()
    }

    onOpenChanged: {
        if (!open) {
            // Cancel any pending preview requests or actions
            if (currentItem && currentItem.previewData !== undefined) {
                currentItem.previewData.cancelAction();
            }
            root.scope.cancelActivation();
            model = undefined;
        }
    }

    onModelChanged: {
        if (previewLoader.active && initialIndex >= 0 && !usedInitialIndex) {
            usedInitialIndex = true;
        }
    }

    Item {
        Repeater {
            id: repeater
            model: root.model
            Item {
                readonly property var previewStack: {
                    if (root.open) {
                        if (index === root.initialIndex) {
                            return root.initialIndexPreviewStack;
                        } else {
                            return root.scope.preview(model.result, root.categoryId);
                        }
                    } else {
                        return null;
                    }
                }
                property var previewModel: {
                    if (previewStack) {
                        return previewStack.getPreviewModel(0);
                    } else {
                        return null;
                    }
                }
            }
        }
    }

    Loader {
        id: previewLoader
        objectName: "loader"
        anchors {
            top: header.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        active: count > 0

        property int index: initialIndex
        onIndexChanged: console.log(index, "index changed")
        readonly property int count: root.model && root.model.count || 0

        sourceComponent: Previews.Preview {
            id: preview
            objectName: "preview" + index
            height: previewLoader.height
            width: previewLoader.width

            property var result
            property int index: 0
        }

        property var previewModel: repeater.itemAt(index).previewModel;
        onPreviewModelChanged: console.log(previewModel)

        onLoaded: {
            item.index = Qt.binding(function() { return index; });
            item.scopeStyle = Qt.binding(function() { return root.scopeStyle; });
            item.previewModel = Qt.binding(function() { return previewLoader.previewModel });
        }
    }

    MouseArea {
        id: processingMouseArea
        objectName: "processingMouseArea"
        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            bottom: parent.bottom
        }

        enabled: root.processing
    }
}
