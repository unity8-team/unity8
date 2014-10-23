import QtQuick 2.0
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0
import "../../Components/Math.js" as MathLocal
import "../../Components"

Showable {
    id: manageFeedsView

    property bool editModeOn: false
    property ListModel feedsModel: null
    property color bgColor: "#f5f5f5"
    readonly property real __feedHeight: units.gu(7)

    signal close()
    signal feedSelected(string feedName)

    // Timer to allow displacement animation to finish before calculating need for
    // reorganizing next time
    Timer {
        id: waitTimer
        interval: 170 // needs to match with the listView moveDisplaced transition duration
        onTriggered: listView.reorganizeIfNeeded()
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        color: bgColor
    }

    Item {
        id: clipper
        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            bottom: parent.bottom
        }
        clip: true
    }

    ListView {
        id: listView

        property FeedDelegate movingItem: null

        function reorganizeIfNeeded() {
            var itemUnderMouse = listView.itemAt(0, dragDetector.mouseY + listView.contentY)
            if (itemUnderMouse && movingItem && itemUnderMouse != movingItem && !waitTimer.running && !moveTransition.running && itemUnderMouse.isFavourite) {
                waitTimer.restart()
                // let's not do any direct model manipulations here.
                // ask app manager to move feed. As it updates the model it will be reflected here as well. Application manager
                // keeps then other models up to date as well.
                fakeDash.feedManager.moveFavouriteFeed(movingItem.feedName, itemUnderMouse.ownIndex)
            }
        }

        function scroll(scrollAmount) {
            if (listView.contentHeight - listView.height > 0) {
                listView.contentY = MathLocal.clamp(listView.contentY + scrollAmount, 0, listView.contentHeight - listView.height)
                listView.reorganizeIfNeeded()
            }
        }

        function resetDelegates() {
            // mark all delegates unchecked
            var i = listView.model.count - 1
            for (i; i >= 0; i--) {
                listView.currentIndex = i
                listView.currentItem.reset()
            }
        }

        function deleteCheckedDelegates() {
            // mark all delegates checked
            var i = listView.model.count - 1
            for (i; i >= 0; i--) {
                listView.currentIndex = i
                if(listView.currentItem.isChecked) {
                    fakeDash.feedManager.removeInstalledFeed(listView.currentItem.feedName)
                }
            }
        }

        function checkAll() {
            // mark all delegates checked
            var i = listView.model.count - 1
            for (i; i >= 0; i--) {
                listView.currentIndex = i
                if(!listView.currentItem.isPersistent) {
                    listView.currentItem.isChecked = true
                }
            }
        }

        parent: clipper
        anchors.fill: parent
        orientation: Qt.Vertical
        model: feedsModel

        moveDisplaced: Transition {
                id: displacedTransition
                property real displaceDuration: listView.movingItem ? waitTimer.interval : 0
                NumberAnimation {id: moveTransition; properties: "y"; duration: displacedTransition.displaceDuration; easing.type: Easing.InOutCubic }
            }
        delegate: FeedDelegate {
            id: feedDelegate
            ownIndex: index
            width: parent.width
            height: manageFeedsView.__feedHeight
            editModeOn: manageFeedsView.editModeOn
            onPressAndHold: manageFeedsView.editModeOn ? manageFeedsView.editModeOn = false : manageFeedsView.editModeOn = true
            onToggleFavourite: isFavourite ? fakeDash.feedManager.unfavouriteFeed(feedName) : fakeDash.feedManager.favouriteFeed(feedName)
            onRemove: fakeDash.feedManager.removeInstalledFeed(feedName)
            onClicked: {
                manageFeedsView.feedSelected(feedName)
                listView.resetDelegates()
                manageFeedsView.editModeOn = false
                manageFeedsView.close()
            }
        }

        section.property: "favourite_m"
        section.criteria: ViewSection.FullString
        section.delegate: Rectangle {
            width: parent.width
            height: units.gu(3)
            color: "#eaeaea"

            Label {
                anchors {
                    left: parent.left
                    leftMargin: units.gu(1)
                    verticalCenter: parent.verticalCenter
                }
                text: section == "true" ? "Home" : "Others"
                fontSize: "small"
                color: "black"
                opacity: 1
            }

            Rectangle {
                id: divider
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: units.dp(1)
                color: "#d8d8d8"
            }
        }

        MouseArea {
            id: dragDetector

            property real pressedY: 0
            property real scrollAreaHeight: units.gu(5)
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }
            width: editModeOn ? manageFeedsView.__feedHeight : 0

            function handleScrolling() {
                if (mouseY < scrollAreaHeight) {
                    if (!scrollTimer.running) {
                        scrollTimer.scrollDown = true
                        scrollTimer.restart()
                    }
                } else if (mouseY > dragDetector.height - scrollAreaHeight) {
                    if (!scrollTimer.running) {
                        scrollTimer.scrollDown = false
                        scrollTimer.restart()
                    }
                } else if (scrollTimer.running) {
                    scrollTimer.stop()
                }
            }

            onPressed: {
                // findDelegate
                var pressedDelegate = listView.itemAt(mouseX, mouseY + listView.contentY)
                if (pressedDelegate) {
                    var mappedToDelegate = mapToItem(pressedDelegate, mouseX, mouseY)
                    if (pressedDelegate && pressedDelegate.moveTargetPressed(mappedToDelegate.x, mappedToDelegate.y)) {
                        listView.interactive = false
                        listView.movingItem = pressedDelegate
                        pressedDelegate.opacity = 0

                        pressedY = mouseY
                        movableFeed.initialY = listView.movingItem.y - listView.contentY
                        movableFeed.visible = true
                    }
                }
            }
            onMouseYChanged: {
                if (listView.movingItem) {
                    handleScrolling()
                    listView.reorganizeIfNeeded()
                    movableFeed.yChange = mouseY - pressedY
                }
            }
            onReleased: {
                scrollTimer.stop()
                if (listView.movingItem) {
                    dragEndAnimation.restart()
                }
            }
        }
    }

    Timer {
        id: scrollTimer
        property bool scrollDown: false
        property real scrollAmount: scrollDown ? -units.gu(0.5) : units.gu(0.5)
        interval: 15
        repeat: true
        onTriggered: {
            listView.scroll(scrollAmount)
        }
    }

    SequentialAnimation {
        id: dragEndAnimation
        ParallelAnimation {
            NumberAnimation {
                target: movableFeed
                property: "yChange"
                to: 0
                duration: 170
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: movableFeed
                property: "initialY"
                to: listView.movingItem ? listView.movingItem.y - listView.contentY : 0
                duration: 170
                easing.type: Easing.InOutCubic
            }
        }
        ScriptAction {
            script: {
                movableFeed.visible = false
                listView.movingItem.opacity = 1
                listView.interactive = true
                listView.movingItem = null
            }
        }

    }

    FeedDelegate {
        id: movableFeed

        property real initialY: 0
        property real yChange: 0

        parent: listView
        width: listView.width
        height: manageFeedsView.__feedHeight
        editModeOn: true
        feedName: listView.movingItem ? listView.movingItem.feedName : ""
        isFavourite: true
        isPersistent: listView.movingItem ? listView.movingItem.isPersistent : false
        visible: false
        y: initialY + yChange
        isChecked: listView.movingItem ? listView.movingItem.isChecked : false
    }

    HeaderWithDivider {
        id: header
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        editModeOn: manageFeedsView.editModeOn

        onBack: {
            manageFeedsView.editModeOn = false
            manageFeedsView.close()
        }
        onLaunchStore: {
            console.log("launch store")
        }
        onSearch: {
            console.log("search")
        }
        onCancel: {
            manageFeedsView.editModeOn = false
            listView.resetDelegates()
        }
        onCheckAll: {
            listView.checkAll()
        }
        onRemove: {
            PopupUtils.open(dialog)
        }
    }

    Component {
         id: dialog
         Dialog {
             id: dialogue
             title: "Multiple feeds"
             text: "Are you sure that you want to remove and unsubscribe from all selected feeds?"
             Button {
                 text: "Yes"
                 onClicked: {
                    listView.deleteCheckedDelegates()
                     PopupUtils.close(dialogue)
                 }
             }
             Button {
                 text: "No"
                 onClicked: PopupUtils.close(dialogue)
             }
         }
    }

}
