import QtQuick 2.0
import Ubuntu.Components 1.1
import "../Components"

Item {
    id: dashFeedDelegate

    property string feedName: feedName_m
    property string feedScreenshot: feed_screenshot_m
    property bool isFavourite: favourite_m
    property bool isPersistent: persistent_m


    signal toggleFavourite(string feedName)

    width: dash.width
    height: dash.height
    clip: true

    Rectangle {
        id: feedBg
        anchors.fill: parent
        color: "#303030"
    }

    Rectangle {
        id: bg
        color: "gray"
        anchors.fill: parent
        visible: !flickable.visible

        Label {
            anchors.centerIn: parent
            text: dashFeedDelegate.feedName
            color: "white"
            fontSize: "large"
        }
    }

    Flickable {
        id: flickable
        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            bottom: parent.bottom
        }
        contentHeight: screenshotImage.height
        flickableDirection: Qt.Vertical
        visible: screenshotImage.source != ""

        Image {
            id: screenshotImage
            width: parent.width
            height: width * sourceSize.height / sourceSize.width
            source: dashFeedDelegate.feedScreenshot != "" ? "graphics/feedScreenshots/" + dashFeedDelegate.feedScreenshot : ""
        }
    }

    FeedHeader {
        id: header
        text: dashFeedDelegate.feedName
        isFavourite: dashFeedDelegate.isFavourite
        onToggleFavourite: dashFeedDelegate.toggleFavourite(feedName)
    }

}
