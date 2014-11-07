import QtQuick 2.0
import Ubuntu.Components 1.1

Item {
    id: feedStoreDelegate

    property color bgColor: "#f5f5f5"
    property color bgColor_subscribed: "#d5d5d5"
    property color fontColor: "#303030"
    property string feedPromoIconSource: feed_promo_icon_m //from model

    signal opened(string feedName)

    width: 100
    height: 62

    Rectangle {
        id: bg
        color: installed_m ? bgColor_subscribed : bgColor
        anchors.fill: parent
    }

    UbuntuShape {
        id: feedIcon
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            margins: units.gu(1.5)
        }
        width: units.gu(18)
        color: "white"
        radius: "medium"
        image: Image {
            sourceSize.width: feedIcon.width
            sourceSize.height: feedIcon.height
            source: feedPromoIconSource != "" ? "graphics/feedArtwork/" + feedPromoIconSource : ""
        }
    }

    Item {
        id: textContainer

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: feedIcon.right
            right: parent.right
            margins: units.gu(1.5)
        }

        Label {
            id: feedName
            anchors {
                top: parent.top
                left: parent.left
                topMargin: units.gu(1)
            }
            text: feedName_m
            fontSize: "small"
            font.bold: true
            color: fontColor
        }

        Label {
            id: feedDescription
            anchors {
                top: feedName.bottom
                left: parent.left
                right: parent.right
                topMargin: units.gu(0.5)
            }
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            height: units.gu(4)
            text: "Lorem ipsum dolor sit amet, error fastidii nec eu, eos aliquando gloriatur in. Oportere voluptaria usu ex. "
            fontSize: "x-small"
            color: fontColor
        }

        Rectangle {
            id: subscribeButton
            anchors {
                top: feedDescription.bottom
                left: parent.left
                topMargin: units.gu(0.5)
            }
            height: units.gu(3)
            width: units.gu(8.5)
            border.width: units.dp(1)
            border.color: fontColor
            color: "transparent"
            radius: units.gu(0.5)
            visible: !persistent_m

            Label {
                anchors.centerIn: parent
                text: installed_m ? "Uninstall" : "Install"
                color: fontColor
                fontSize: "small"
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -units.gu(0.5)
                onClicked: activity.start()
            }
        }

        Rectangle {
            id: previewAndLaunchButton
            anchors {
                top: feedDescription.bottom
                left: subscribeButton.right
                leftMargin: units.gu(1)
                topMargin: units.gu(0.5)
            }
            height: units.gu(3)
            width: units.gu(8.5)
            border.width: units.dp(1)
            border.color: installed_m ? color : fontColor
            color: installed_m ? "#dd4814" : "transparent"
            Behavior on color {ColorAnimation {duration: 200}}
            radius: units.gu(0.5)
            opacity: installed_m ? 1 : 0.5
            Label {
                anchors.centerIn: parent
                text: installed_m ? "Open" : "Preview"
                color: installed_m ? "white" : fontColor
                fontSize: "small"
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -units.gu(0.5)
                onClicked: if (installed_m) feedStoreDelegate.opened(feedName_m)
            }
        }
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

    SubscribingActivity {
        id: activity
        anchors.fill: parent
        onFinished: {
            if (installed_m) {
                feedManager.unsubscribeFromFeed(feedName_m)
                feedStore.unsubscribedFromFeed(feedName_m)
            } else {
                feedManager.subscribeToFeed(feedName_m)
            }
        }
    }
}
