/*
 * Copyright 2014 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
 *          Daniel d'Andrada <daniel.dandrada@canonical.com>
 */

import QtQuick 2.0
import Ubuntu.Components 1.1
import "../Components"
import "FakeImplementations/FakeDash"
import "FakeImplementations/FeedStore"

// to launch apps
import Unity.Application 0.1



Item {
    id: root

    // to be read from outside
    readonly property bool dragged: dragArea.moving
    signal clicked()
    signal closed()
    signal feedNeedsDashFocusing(string feedName)

    // to be set from outside
    property bool interactive: true
    property bool dropShadow: true
    property real maximizedAppTopMargin
    property alias swipeToCloseEnabled: dragArea.enabled
    property bool closeable

    property var application: null
    property var feedManager: null

    Loader {
        id: appWindowLoader

        y: dragArea.distance
        width: parent.width
        height: parent.height
        sourceComponent: {
            if (application && application.appId == "unity8-dash") {
                return fakeDashComponent
            } else if (application && (application.appId == "store-feed")) {
                return storeFeedComponent
            } else if (application
                       && application.appId.indexOf("feed") > -1) {
                return fakeFeedComponent
            }  else {
                return appWindowComponent
            }
        }

        asynchronous: true

        Binding {
            target: appWindowLoader.item
            property: "application"
            value: root.application
        }

        Binding {
            target: appWindowLoader.item
            property: "feedManager"
            value: root.feedManager
        }
    }

    function focusDashToFeed(feedName) {
        if (application.appId == "unity8-dash") {
            appWindowLoader.item.activateFeed(feedName)
        } else {
            // do nothing
        }
    }

    function handleFeedFavourited(feedName, focusToFeed) {
        if (focusToFeed) {
            root.feedNeedsDashFocusing(feedName)
        }

        var foundModelIndex = feedManager.findFirstModelIndexByName(feedManager.manageDashModel,feedName)
        if (foundModelIndex != -1) {
            ApplicationManager.stopApplication(feedManager.manageDashModel.get(foundModelIndex).feedId_m)
        }

        // Focus to dash
        ApplicationManager.requestFocusApplication("unity8-dash")


    }
    function handleFeedUnfavourited(feedName) {
        // Find a way to launch an application to app stack position 1. meaning next from the currently running.
        console.log("feedUnfavourited", feedName, "-> do nothing now. Should possibly start a standalone feed instance.")
    }

    Component {
        id: fakeDashComponent

        FakeDash {
            anchors.fill: parent
            anchors.topMargin: maximizedAppTopMargin
            onFeedLaunched: {
                var foundModelIndex = feedManager.findFirstModelIndexByName(feedManager.manageDashModel,feedName)
                if (foundModelIndex != -1) {
                    shell.activateApplication(feedManager.manageDashModel.get(foundModelIndex).feedId_m)
                }
            }
            onFeedUninstalled: {
                var foundModelIndex = feedManager.findFirstModelIndexByName(feedManager.allFeedsModel, feedName)
                if (foundModelIndex != -1) {
                    ApplicationManager.stopApplication(feedManager.allFeedsModel.get(foundModelIndex).feedId_m)
                }
            }
            onFeedUnfavourited: handleFeedUnfavourited(feedName)
            onFeedFavourited: handleFeedFavourited(feedName, false)
            onStoreLaunched: {
                shell.activateApplication("store-feed")
            }
        }
    }

    Component {
        id: storeFeedComponent

        FeedStore {
            id: feedStore

            anchors.fill: parent
            anchors.topMargin: maximizedAppTopMargin
            feedManager: root.feedManager
            state: "shown"
            showBack: false
        }
    }

    Component {
        id: fakeFeedComponent
        DashFeedDelegate {
            id: dashFeedDelegate
            anchors.fill: parent
            anchors.topMargin: maximizedAppTopMargin
            Component.onCompleted: setDelegateData()

            function setDelegateData() {
                var foundModelIndex = feedManager.findFirstModelIndexById(feedManager.manageDashModel, application.appId)
                if (foundModelIndex == -1) {
                    console.log("Error. corresponding feed not found. id:", application.appId)
                    return false
                } else {
                    dashFeedDelegate.feedName = feedManager.manageDashModel.get(foundModelIndex).feedName_m
                    dashFeedDelegate.feedScreenshot = feedManager.manageDashModel.get(foundModelIndex).feed_screenshot_m
                    dashFeedDelegate.isFavourite = feedManager.manageDashModel.get(foundModelIndex).favourite_m
                    dashFeedDelegate.isPersistent = feedManager.manageDashModel.get(foundModelIndex).persistent_m
                    return true
                }
            }

            onToggleFavourite: {
                // duplicate code. can be found from fake dash as well. handle somehow better!!
                var originalFavouriteState = isFavourite

                // let feedManager handle toggling in model. It will propagate to the model and delegates here.
                isFavourite ? feedManager.unfavouriteFeed(feedName) : feedManager.favouriteFeed(feedName)

                // handle action
                originalFavouriteState ? handleFeedUnfavourited(feedName) : handleFeedFavourited(feedName, true)
            }
        }
    }

    Component {
        id: appWindowComponent

        Item {
            objectName: "appWindowWithShadow"

            y: dragArea.distance
            width: parent.width
            height: parent.height
            property alias application: appWindow.application

            BorderImage {
                anchors {
                    fill: appWindow
                    margins: -units.gu(2)
                }
                source: "graphics/dropshadow2gu.sci"
                opacity: root.dropShadow ? .3 : 0
                Behavior on opacity { UbuntuNumberAnimation {} }
            }

            ApplicationWindow {
                id: appWindow
                anchors {
                    fill: parent
                    topMargin: appWindow.fullscreen ? 0 : maximizedAppTopMargin
                }

                interactive: root.interactive
            }
        }
    }

    DraggingArea {
        id: dragArea
        objectName: "dragArea"
        anchors.fill: parent

        property bool moving: false
        property real distance: 0

        readonly property real minSpeedToClose: units.gu(40)

        onDragValueChanged: {
            if (!dragging) {
                return;
            }
            moving = moving || Math.abs(dragValue) > units.gu(1)
            if (moving) {
                distance = dragValue;
            }
        }

        onClicked: {
            if (!moving) {
                root.clicked();
            }
        }

        onDragEnd: {
            if (!root.closeable) {
                animation.animate("center")
                return;
            }

            // velocity and distance values specified by design prototype
            if ((dragVelocity < -minSpeedToClose && distance < -units.gu(8)) || distance < -root.height / 2) {
                animation.animate("up")
            } else if ((dragVelocity > minSpeedToClose  && distance > units.gu(8)) || distance > root.height / 2) {
                animation.animate("down")
            } else {
                animation.animate("center")
            }
        }

        UbuntuNumberAnimation {
            id: animation
            objectName: "closeAnimation"
            target: dragArea
            property: "distance"
            property bool requestClose: false

            function animate(direction) {
                animation.from = dragArea.distance;
                switch (direction) {
                case "up":
                    animation.to = -root.height * 1.5;
                    requestClose = true;
                    break;
                case "down":
                    animation.to = root.height * 1.5;
                    requestClose = true;
                    break;
                default:
                    animation.to = 0
                }
                animation.start();
            }

            onRunningChanged: {
                if (!running) {
                    dragArea.moving = false;
                    if (requestClose) {
                        root.closed();
                    } else {
                        dragArea.distance = 0;
                    }
                }
            }
        }
    }
}
