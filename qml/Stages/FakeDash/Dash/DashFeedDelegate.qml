import QtQuick 2.0
import Ubuntu.Components 1.1

Item {
    id: feedDelegate

    width: dash.width
    height: dash.height

    Rectangle {
        id: bg
        color: "gray"
        anchors.fill: parent
        visible: !flickable.visible

        Label {
            anchors.centerIn: parent
            text: feedName_m
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
            property string screenshotSource: feed_screenshot_m
            width: parent.width
            height: width * sourceSize.height / sourceSize.width
            source: feed_screenshot_m != "" ? "graphics/feedScreenshots/" + screenshotSource : ""
        }
    }

}
