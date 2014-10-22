import QtQuick 2.0
import Ubuntu.Components 1.1
import "FeedManager"
import "../Components"

Item {
    id: dash

    property ListModel dashModel: null
    property ListModel manageDashModel: null

    ListView {
        id: listView

        anchors.fill: parent
        model: dashModel
        orientation: Qt.Horizontal
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightFollowsCurrentItem: true
        boundsBehavior: ListView.DragOverBounds

        delegate: Rectangle {
            width: dash.width
            height: dash.height
            color: "gray"

            Label {
                anchors.centerIn: parent
                text: feedName_m
                color: "white"
                fontSize: "large"
            }
        }
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

        onClose: {
            hide()
        }
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

