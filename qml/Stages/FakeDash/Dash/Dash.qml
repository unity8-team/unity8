import QtQuick 2.0
import Ubuntu.Components 1.1
import "FeedManager"
import "../Components"

Item {
    id: dash

    property ListModel dashModel: null
    property ListModel manageDashModel: null

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
            console.log("feed not favourite feed. Needs to be launched as Non-favourite")
        }
    }

    ListView {
        id: listView

        anchors.fill: parent
        model: dashModel
        orientation: Qt.Horizontal
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightFollowsCurrentItem: true
        highlightMoveDuration: 300
        boundsBehavior: ListView.DragOverBounds

        delegate: DashFeedDelegate {
            width: dash.width
            height: dash.height
        }
        visible: Math.abs(feedManager.y - feedManagerRevealer.openedValue) > 0.0001 //perf
    }

    FeedManager {
        id: feedManager
        width: parent.width
        height: parent.height
        feedsModel: manageDashModel

        property int animationDuration: UbuntuAnimation.BriskDuration
        showAnimation: NumberAnimation { property: "y"; duration: feedManager.animationDuration; to: feedManagerRevealer.openedValue; easing: UbuntuAnimation.StandardEasing }
        hideAnimation: NumberAnimation { property: "y"; duration: feedManager.animationDuration; to: feedManagerRevealer.closedValue; easing: UbuntuAnimation.StandardEasing }
        shown: false

        onClose: hide()
        onFeedSelected: dash.activateFeed(feedName)
        visible: Math.abs(feedManager.y - feedManagerRevealer.closedValue) > 0.0001

    }

    Revealer {
        id: feedManagerRevealer

        target: feedManager
        orientation: Qt.Vertical
        direction: Qt.RightToLeft
        anchors.fill: parent
        hintDisplacement: units.gu(1)
        handleSize: target.shown ? units.gu(0) : units.gu(2)
        openedValue: 0
        closedValue: dash.height
        width: parent.width
    }

}
