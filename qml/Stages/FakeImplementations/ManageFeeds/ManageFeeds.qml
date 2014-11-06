import QtQuick 2.0
import Ubuntu.Components 1.1
import "../Components"

Item {
    id: manageFeeds

    property bool fullyOpen: Math.abs(manageFeedsView.y - manageFeedsRevealer.openedValue) < 0.0001
    property var feedManager: null

    signal feedSelected(string feedName)
    signal feedUninstalled(string feedName)
    signal feedUnfavourited(string feedName)
    signal feedFavourited(string feedName)
    signal storeLaunched()
    signal resetPrototypeSelected()

    function hide() {
        manageFeedsView.hide()
    }

    function show() {
        manageFeedsView.show()
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
        onResetPrototypeSelected: {
            hide()
            manageFeeds.resetPrototypeSelected()
        }
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
        closedValue: parent.height
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
