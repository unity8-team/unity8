import QtQuick 2.0
import Ubuntu.Components 0.1
import "../Components"

Item {
    id: headerWithDivider

    property alias text: label.text
    property bool editModeOn: false

    width: units.gu(40)
    height: headerContainer.height + divider.height

    signal back()
    signal launchStore()
    signal search()

    signal cancel()
    signal checkAll()
    signal remove()
    signal resetPrototypeSelected()


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

            visible: opacity > 000.1
            opacity: !editModeOn ? 1 : 0
            Behavior on opacity {NumberAnimation{duration: UbuntuAnimation.FastDuration}}
            scale: !editModeOn ? 1 : 0.5
            Behavior on scale {NumberAnimation{duration: UbuntuAnimation.FastDuration}}

            MouseArea {
                anchors.fill: parent
                anchors.margins: -units.gu(1.5)
                onClicked: headerWithDivider.back()
            }
        }

        Image {
            id: cancelButton
            anchors.centerIn: backButton
            height: units.gu(2.5)
            width: height * sourceSize.width / sourceSize.height
            source: "graphics/cancel.svg"

            visible: opacity > 000.1
            opacity: editModeOn ? 1 : 0
            Behavior on opacity {NumberAnimation{duration: UbuntuAnimation.FastDuration}}
            scale: editModeOn ? 1 : 0.5
            Behavior on scale {NumberAnimation{duration: UbuntuAnimation.FastDuration}}

            MouseArea {
                anchors.fill: parent
                anchors.margins: -units.gu(1.5)
                onClicked: headerWithDivider.cancel()
            }
        }

        Label {
            id: label
            anchors {
                left: backButton.right
                leftMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }

            text: editModeOn ? "Edit" : "Manage"
            color: "#5b5b5b"
            opacity: 1
            font.family: "Ubuntu"
            font.weight: Font.Light
            fontSize: "x-large"
            elide: Text.ElideRight

            MouseArea {
                id: resetArea
                anchors.fill: parent
                onPressAndHold: header.resetPrototypeSelected()
            }
        }

        UbuntuShape {
            id: storeIcon
            anchors {
                right: searchIcon.left
                rightMargin: units.gu(2.5)
                verticalCenter: parent.verticalCenter
            }
            height: units.gu(4)
            width: height
            color: "white"
            //radius: "medium"
            borderSource: "none"
            visible: opacity > 000.1
            opacity: !editModeOn ? 1 : 0
            Behavior on opacity {NumberAnimation{duration: UbuntuAnimation.FastDuration}}
            scale: !editModeOn ? 1 : 0.5
            Behavior on scale {NumberAnimation{duration: UbuntuAnimation.FastDuration}}

            image: Image {
                sourceSize.width: storeIcon.width
                sourceSize.height: storeIcon.height
                source: "graphics/ubuntu-store.svg"
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -units.gu(1.5)
                onClicked: headerWithDivider.launchStore()
            }
        }

        Image {
            id: checkAllIcon
            anchors.centerIn: storeIcon
            height: units.gu(2.5)
            width: height * sourceSize.width / sourceSize.height
            source: "graphics/select.svg"

            visible: opacity > 000.1
            opacity: editModeOn ? 1 : 0
            Behavior on opacity {NumberAnimation{duration: UbuntuAnimation.FastDuration}}
            scale: editModeOn ? 1 : 0.5
            Behavior on scale {NumberAnimation{duration: UbuntuAnimation.FastDuration}}

            MouseArea {
                anchors.fill: parent
                anchors.margins: -units.gu(1.5)
                onClicked: headerWithDivider.checkAll()
            }
        }

        Image {
            id: searchIcon
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                margins: units.gu(2)
            }
            width: height
            source: "graphics/search.svg"

            visible: opacity > 000.1
            opacity: !editModeOn ? 1 : 0
            Behavior on opacity {NumberAnimation{duration: UbuntuAnimation.FastDuration}}
            scale: !editModeOn ? 1 : 0.5
            Behavior on scale {NumberAnimation{duration: UbuntuAnimation.FastDuration}}

            MouseArea {
                anchors.fill: parent
                anchors.margins: -units.gu(1.5)
                onClicked: headerWithDivider.search()
            }
        }

        Image {
            id: deleteIcon
            anchors.fill: searchIcon
            width: height
            source: "graphics/edit-delete.svg"

            visible: opacity > 000.1
            opacity: editModeOn ? 1 : 0
            Behavior on opacity {NumberAnimation{duration: UbuntuAnimation.FastDuration}}
            scale: editModeOn ? 1 : 0.5
            Behavior on scale {NumberAnimation{duration: UbuntuAnimation.FastDuration}}

            MouseArea {
                anchors.fill: parent
                anchors.margins: -units.gu(1.5)
                onClicked: headerWithDivider.remove()
            }
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
