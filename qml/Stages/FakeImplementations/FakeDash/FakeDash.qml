import QtQuick 2.0
import Ubuntu.Components 1.1
import "ManageFeedsView"
import "../Components"

Item {
    id: fakeDash

    property var feedManager: null
    property bool clipDash: true
    property bool clipFeed: true

    signal feedLaunched(string feedName)
    signal feedUninstalled(string feedName)
    signal feedUnfavourited(string feedName)
    signal feedFavourited(string feedName)
    signal storeLaunched()

    function activateFeed(feedName) {
        var feedModelIndex = -1
        // find the model index
        for (var i = 0; i < listView.model.count; i++) {
            if (listView.model.get(i).feedName_m == feedName) {
                feedModelIndex = i
            }
        }

        if (feedModelIndex != -1) {
            // focus to correct feed
            listView.currentIndex = feedModelIndex
        } else {
            fakeDash.feedLaunched(feedName)
        }
    }

    Label {
        id: emptyStateText
        text: "You need to have at least one item in 'Home'! Swipe up from the bottom to add one now."
        width: 3/4 * parent.width
        wrapMode: Text.WordWrap
        fontSize: "large"
        anchors.centerIn: parent
        color: "white"
        visible: listView.model.count == 0
    }

    ListView {
        id: listView

        anchors.fill: parent
        model: feedManager ? feedManager.dashModel : null
        orientation: Qt.Horizontal
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightFollowsCurrentItem: true
        highlightMoveDuration: 300
        boundsBehavior: ListView.DragOverBounds
        clip: clipDash
        delegate: DashFeedDelegate {
            width: fakeDash.width
            height: fakeDash.height
            onToggleFavourite: {

                // duplicate code. handle somehow better!!
                var originalFavouriteState = isFavourite

                // let feedManager handle toggling in model. It will propagate to the model and delegates here.
                isFavourite ? fakeDash.feedManager.unfavouriteFeed(feedName) : fakeDash.feedManager.favouriteFeed(feedName)

                // signal
                originalFavouriteState ? fakeDash.feedUnfavourited(feedName) : fakeDash.feedFavourited(feedName)
            }
        }
        visible: Math.abs(manageFeedsView.y - manageFeedsRevealer.openedValue) > 0.0001 //perf fix
    }

    ManageFeedsView {
        id: manageFeedsView
        width: parent.width
        height: parent.height
        feedsModel: feedManager ? feedManager.manageDashModel : null

        property int animationDuration: UbuntuAnimation.BriskDuration
        showAnimation: NumberAnimation { property: "y"; duration: manageFeedsView.animationDuration; to: manageFeedsRevealer.openedValue; easing: UbuntuAnimation.StandardEasing }
        hideAnimation: NumberAnimation { property: "y"; duration: manageFeedsView.animationDuration; to: manageFeedsRevealer.closedValue; easing: UbuntuAnimation.StandardEasing }
        shown: false

        onClose: hide()
        onFeedSelected: fakeDash.activateFeed(feedName)
        onFeedUninstalled: fakeDash.feedUninstalled(feedName)
        onFeedUnfavourited: fakeDash.feedUnfavourited(feedName)
        onFeedFavourited: fakeDash.feedFavourited(feedName)
        onStoreLaunched: fakeDash.storeLaunched()

        visible: Math.abs(manageFeedsView.y - manageFeedsRevealer.closedValue) > 0.0001 //perf fix

    }

    Revealer {
        id: manageFeedsRevealer

        target: manageFeedsView
        orientation: Qt.Vertical
        direction: Qt.RightToLeft
        anchors.fill: parent
        hintDisplacement: units.gu(1)
        handleSize: target.shown ? units.gu(0) : units.gu(2)
        openedValue: 0
        closedValue: fakeDash.height
        width: parent.width
    }

    Rectangle {
        id: dropShadow
        anchors {
            left: parent.left
            right: parent.right
            bottom: manageFeedsView.top
        }
        height: units.gu(0.5)
        visible: manageFeedsView.visible
        opacity: 0.2
        gradient: Gradient {
                 GradientStop { position: 0.0; color: "transparent" }
                 GradientStop { position: 0.8; color: "black" }
                 GradientStop { position: 1.0; color: "black" }
             }
    }

    Image {
        id: manageFeedsHandle
        height: manageFeedsRevealer.handleSize
        width: sourceSize.width / sourceSize.height * height
        anchors {
            bottom: manageFeedsView.top
            horizontalCenter: parent.horizontalCenter
        }
        source: "graphics/overview_hint.png"
    }

}
