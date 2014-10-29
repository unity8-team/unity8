import QtQuick 2.0
import Ubuntu.Components 1.1

Item {
    id: feedStoreDelegate

    property color bgColor: "#f5f5f5"
    property color bgColor_subscribed: "#e5e5e5"
    property color fontColor: "#303030"

    width: 100
    height: 62

    Rectangle {
        id: bg
        color: installed_m ? bgColor_subscribed : bgColor
        anchors.fill: parent
    }

    Rectangle {
        id: feedIcon
        color: "white"
        radius: units.gu(1.5)
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            margins: units.gu(1.5)
        }
        width: units.gu(18)
        opacity: 0.8
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
            width: units.gu(12)
            border.width: units.dp(1)
            border.color: fontColor
            color: "transparent"
            radius: units.gu(0.5)
            visible: !persistent_m
            Rectangle {
                anchors.fill: parent
            }

            Label {
                anchors.centerIn: parent
                text: installed_m ? "Unsubscribe" : "Subscribe"
                color: fontColor
                fontSize: "small"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: activity.start() //installed_m ? feedManager.unsubscribeFromFeed(feedName_m) : feedManager.subscribeToFeed(feedName_m)
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
        onFinished: installed_m ? feedManager.unsubscribeFromFeed(feedName_m) : feedManager.subscribeToFeed(feedName_m)
    }
}
