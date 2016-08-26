/*
 * Copyright (C) 2014 Canonical, Ltd.
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
import Dash 0.1
import "../Components"

Item {
    id: root

    // Properties set by parent
    property var scope: null

    // Properties used by parent
    readonly property bool processing: scope ? (scope.searchInProgress || scope.activationInProgress) : false

    // Signals
    signal backClicked()
    signal storeClicked()
    signal requestFavorite(string scopeId, bool favorite)
    signal requestFavoriteMoveTo(string scopeId, int index)
    signal requestRestore(string scopeId)

    state: "browse"

    property var scopeStyle: ScopeStyle {
    }

    onStateChanged: {
        if (state == "edit") {
            // As per design entering edit mode clears the possible existing search
            header.resetSearch(false /* false == unfocus */);
        }
    }

    DashBackground {
        anchors.fill: parent
    }

    DashPageHeader {
        id: header
        objectName: "pageHeader"
        title: i18n.tr("Manage")
        width: parent.width
        clip: true
        showBackButton: true
        backIsClose: root.state == "edit"
        storeEntryEnabled: root.state == "browse"
        searchEntryEnabled: false
        scopeStyle: root.scopeStyle
        onBackClicked: {
            if (backIsClose) {
                root.state = "browse"
            } else {
                if (flickable.contentY > 0) {
                    flickable.clip = true;
                }
                root.backClicked()
            }
        }
        onStoreClicked: root.storeClicked();
        z: 1
    }

    Autoscroller {
        id: autoscroller
        objectName: "scopesListAutoscroller"

        anchors {
            top: header.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        enabled: root.state === "edit"
        flickable: flickable

        Flickable {
            id: flickable
            objectName: "scopesListFlickable"

            anchors.fill: parent

            // Reset to false each time the list is opened. See header.onBackClicked
            onVisibleChanged: clip = !visible
            contentWidth: root.width
            contentHeight: column.height
            onContentHeightChanged: returnToBounds();
            Column {
                id: column
                Repeater {
                    model: scope ? scope.categories : null

                    delegate: Loader {
                        asynchronous: true
                        width: root.width
                        active: results.count > 0
                        visible: active
                        sourceComponent: ScopesListCategory {
                            objectName: "scopesListCategory" + categoryId

                            Mouse.forwardTo: [autoscroller]
                            model: results
                            title: {
                                if (isFavoritesFeed) return i18n.tr("Home");
                                else if (isAlsoInstalled) return i18n.tr("Also installed");
                                else return name;
                            }

                            editMode: root.state === "edit"

                            scopeStyle: root.scopeStyle
                            isFavoritesFeed: categoryId == "favorites"
                            isAlsoInstalled: categoryId == "other"

                            onRequestFavorite: root.requestFavorite(scopeId, favorite);
                            onRequestEditMode: root.state = "edit";
                            onRequestScopeMoveTo: root.requestFavoriteMoveTo(scopeId, index);
                            onRequestActivate: root.scope.activate(result, categoryId);
                            onRequestRestore: root.requestRestore(scopeId);

                            readonly property var contentYChangedTarget: isFavoritesFeed && dragItem.visible ? flickable : null
                            property double flickableContentYDrag: 0
                            onContentYChangedTargetChanged: {
                                if (contentYChangedTarget) {
                                    flickableContentYDrag = flickable.contentY
                                }
                            }


                            // Since tracking the drag item can change the flickable
                            // size, this "kill switch" prevents overscrolling locally.
                            // The Autoscroller should take care of everything else.
                            property bool overscrolling: false
                            Mouse.onReleased: overscrolling = false
                            Connections {
                                target: flickable
                                onAtYEndChanged: {
                                    if (flickable.atYEnd && Mouse.pressed) {
                                        overscrolling = true;
                                    }
                                }
                            }

                            Connections {
                                target: contentYChangedTarget
                                onContentYChanged: {
                                    if (overscrolling) {
                                        return;
                                    }
                                    dragItem.y += (flickable.contentY - flickableContentYDrag);
                                    flickableContentYDrag = flickable.contentY
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
