import QtQuick 2.0
import Ubuntu.Components 0.1

Item {
    id: headerWithDivider

    property alias text: label.text
    property bool showBack: false
    property bool useUbuntuGraphicInsteadOfText: false
    property bool showFavIcon: false
    property bool isFavourite: false

    signal back()
    signal toggleFavourite()

    width: units.gu(40)
    height: headerContainer.height + divider.height

    Rectangle {
        id: bg
        anchors.fill: parent
        color: "#f5f5f5"
    }

    Item {
        id: headerContainer
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: units.gu(7)

        Image {
            id: backButton
            anchors {
                left: parent.left
                leftMargin: units.gu(1.5)
                verticalCenter: parent.verticalCenter
            }
            height: units.gu(2.5)
            width: showBack ? height * sourceSize.width/sourceSize.height : 0
            source: "graphics/go-previous.svg"

            visible: showBack
            Behavior on opacity {NumberAnimation{duration: UbuntuAnimation.FastDuration}}

            MouseArea {
                anchors.fill: parent
                anchors.margins: -units.gu(1.5)
                onClicked: headerWithDivider.back()
            }
        }

        Label {
            id: label
            anchors {
                left: backButton.right
                leftMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }

            text: ""
            color: "#5b5b5b"
            visible: !useUbuntuGraphicInsteadOfText
            font.family: "Ubuntu"
            font.weight: Font.Light
            fontSize: "x-large"
            elide: Text.ElideRight
        }

        Image {
            id: ubuntuGraphic
            anchors {
                left: backButton.right
                leftMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }
            height: units.gu(3.5)
            width: height * sourceSize.width/sourceSize.height
            visible: useUbuntuGraphicInsteadOfText
            source: "graphics/home-feed-logo.jpg"
        }

        Image {
            id: favIcon
            anchors {
                right: searchIcon.left
                rightMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }
            height: units.gu(2.5)
            width: sourceSize.width / sourceSize.height * height
            source: isFavourite ? "graphics/starred.svg" : "graphics/non-starred.svg"
            visible: showFavIcon
            MouseArea {
                anchors.fill: parent
                anchors.margins: -units.gu(1.5)
                onClicked: headerWithDivider.toggleFavourite()
            }
        }

        Image {
            id: searchIcon
            anchors {
                right: parent.right
                rightMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }
            height: units.gu(2.5)
            width: sourceSize.width / sourceSize.height * height
            source: "graphics/search.svg"
        }
    }

    HeaderDivider {
        id: divider

        height: units.gu(2)
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        opacity: 0.3
    }
}
