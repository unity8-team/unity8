import QtQuick 2.0
import Ubuntu.Components 0.1

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


    Item {
        id: headerContainer
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: units.gu(6)

        Image {
            id: backButton
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                margins: units.gu(1.5)
            }
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
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                margins: units.gu(1.5)
            }
            width: height
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

            text: "Manage"
            color: "#f3f3e7"
            opacity: 0.6
            font.family: "Ubuntu"
            font.weight: Font.Light
            fontSize: "x-large"
            elide: Text.ElideRight
            style: Text.Raised
            styleColor: "black"
        }

        Image {
            id: storeIcon
            anchors {
                right: searchIcon.left
                top: parent.top
                bottom: parent.bottom
                margins: units.gu(1.5)
                rightMargin: units.gu(2.5)
            }
            width: height
            source: "graphics/stock_application.svg"

            visible: opacity > 000.1
            opacity: !editModeOn ? 1 : 0
            Behavior on opacity {NumberAnimation{duration: UbuntuAnimation.FastDuration}}
            scale: !editModeOn ? 1 : 0.5
            Behavior on scale {NumberAnimation{duration: UbuntuAnimation.FastDuration}}

            MouseArea {
                anchors.fill: parent
                anchors.margins: -units.gu(1.5)
                onClicked: headerWithDivider.launchStore()
            }
        }

        Image {
            id: checkAllIcon
            anchors.fill: storeIcon
            width: height
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
                margins: units.gu(1.5)
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
    }
}
