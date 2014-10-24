import QtQuick 2.0
import Ubuntu.Components 1.1

Item {
    id: dashFeedDelegate

    property string feedName: feedName_m
    property string feedScreenshot: feed_screenshot_m

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
        anchors.fill: parent
        contentHeight: screenshotImage.height
        flickableDirection: Qt.Vertical
        visible: screenshotImage.source != ""

        Image {
            id: screenshotImage
            width: parent.width
            height: width * sourceSize.height / sourceSize.width
            source: dashFeedDelegate.feedScreenshot != "" ? "graphics/feedScreenshots/" + dashFeedDelegate.feedScreenshot : ""
            onSourceChanged: console.log("source", source)
        }
    }

}
