import QtQuick 2.0
import Ubuntu.Components 1.1
import "../Components"

Item {
    id: dashFeedDelegate

    property var feedManager: null
    property string feedName: feedName_m
    property string feedScreenshot: feed_screenshot_m
    property string customSourceFile: custom_qml_file_m
    property bool isFavourite: favourite_m
    property bool isPersistent: persistent_m


    signal toggleFavourite(string feedName)
    signal applicationLaunched(string appId)

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
        visible: customSourceFile == "" && feedScreenshot == ""

        Label {
            anchors.centerIn: parent
            text: dashFeedDelegate.feedName
            color: "white"
            fontSize: "large"
        }
    }

    Loader {
        id: contentLoader
        source: customSourceFile != "" ? "CustomFeeds/" + customSourceFile : ""
        sourceComponent: defaultFlickableComponent
        asynchronous: true
        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            bottom: parent.bottom
        }

        Binding {
            target: contentLoader.item
            property: "feedManager"
            value: dashFeedDelegate.feedManager
        }

        Connections {
            target: contentLoader.item
            onApplicationLaunched: dashFeedDelegate.applicationLaunched(appId)
            ignoreUnknownSignals: true
        }

    }

    Component {
        id: defaultFlickableComponent

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
            }
        }
    }

    FeedHeader {
        id: header
        text: dashFeedDelegate.feedName
        anchors {
            left: parent.left
            right: parent.right
        }
        useUbuntuGraphicInsteadOfText: customSourceFile != "" // Not really generic this way but works since apps feed is the only custom one.
        isFavourite: dashFeedDelegate.isFavourite
        onToggleFavourite: dashFeedDelegate.toggleFavourite(feedName)
    }

}
