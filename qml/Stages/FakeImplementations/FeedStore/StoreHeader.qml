import QtQuick 2.0
import Ubuntu.Components 0.1
import "../Components"

Item {
    id: headerWithDivider

    property alias text: label.text
    property bool showBack: false

    signal back()

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
            width: height * sourceSize.width/sourceSize.height
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

            text: "Feed Store"
            color: "#5b5b5b"
            opacity: 1
            font.family: "Ubuntu"
            font.weight: Font.Light
            fontSize: "x-large"
            elide: Text.ElideRight
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
