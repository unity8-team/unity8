import QtQuick 2.0
import Ubuntu.Components 1.1

Item {
    id: feedStore

    property var feedManager: null
    property alias showBack: header.showBack //whether to show back button in header or not
    property color bgColor: "black"

    function show() {
        feedStore.state = "shown"
    }

    function hide() {
        feedStore.state = "hidden"
    }

    Rectangle {
        id: bg
        anchors.fill: listView
        color: bgColor
    }

    ListView {
        id: listView
        width: parent.width
        anchors {
            top: header.bottom
            bottom: parent.bottom
        }
        x: feedStore.state == "shown" ? 0 : listView.width
        Behavior on x {NumberAnimation{duration: UbuntuAnimation.BriskDuration; easing: UbuntuAnimation.StandardEasing}}
        visible: Math.abs(listView.x - listView.width) > 0.0001 //perf fix
        model: feedManager.allFeedsModel
        delegate: FeedStoreDelegate {
            id: feedStoreDelegate
            width: parent.width
            height: units.gu(15)
        }
    }

    StoreHeader {
        id: header
        anchors.left: listView.left
        onBack: feedStore.hide()
        text: "Feed Store"
        showFavIcon: false
        isFavourite: false
    }

    state: "hidden"
    states: [
        State {
            name: "shown"
        },
        State {
            name: "hidden"
        }
    ]
}
