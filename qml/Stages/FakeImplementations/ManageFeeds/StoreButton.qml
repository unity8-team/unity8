import QtQuick 2.0
import Ubuntu.Components 1.1

Rectangle {
    id: staticStoreButton
    color: "#dd4814"
    width: units.gu(40)
    height: units.gu(6)

    Label {
        anchors.centerIn: parent
        color: "white"
        fontSize: "medium"
        text: "Get more"
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.top
        }
        height: units.gu(0.5)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.8; color: "black" }
            GradientStop { position: 1.0; color: "black" }
        }
        opacity: 0.15
    }

    UbuntuShape {
        id: storeIcon
        anchors {
            left: parent.left
            leftMargin: units.gu(1)
            verticalCenter: parent.verticalCenter
        }
        radius: "medium"
        height: units.gu(5)
        width: height
        borderSource: "none"

        image: Image {
            sourceSize.width: storeIcon.width
            sourceSize.height: storeIcon.height
            source: "graphics/ubuntu-store.svg"
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            manageFeedsView.editModeOn = false
            listView.resetDelegates()
            manageFeedsView.close()
            manageFeeds.storeLaunched()
        }
    }
}
