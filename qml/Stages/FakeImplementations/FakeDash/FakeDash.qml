import QtQuick 2.0
import Ubuntu.Components 1.1
import "../Components"

Item {
    id: fakeDash

    property var feedManager: null
    property bool clipDash: true
    property bool clipFeed: true

    signal feedLaunched(string feedName)
    signal applicationLaunched(string appId)
    signal feedUnfavourited(string feedName)

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
        cacheBuffer: 1000
        delegate: DashFeedDelegate {
            width: fakeDash.width
            height: fakeDash.height
            feedManager: fakeDash.feedManager
            onToggleFavourite: {
                // if in dash should always be initially favourite. There for no need to check if needs to be
                // favourited or unfavourited
                fakeDash.feedManager.unfavouriteFeed(feedName)
                fakeDash.feedUnfavourited(feedName)
            }

            onApplicationLaunched: fakeDash.applicationLaunched(appId)
        }
    }
}
