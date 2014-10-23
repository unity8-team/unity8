import QtQuick 2.0
import Ubuntu.Components 1.1
import "ManageFeedsView"
import "../Components"

Item {
    id: fakeDash

    property var feedManager: null

    signal feedLaunch(string feedName)

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
            fakeDash.feedLaunch(feedName)
        }
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

        delegate: DashFeedDelegate {
            width: fakeDash.width
            height: fakeDash.height
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

}
