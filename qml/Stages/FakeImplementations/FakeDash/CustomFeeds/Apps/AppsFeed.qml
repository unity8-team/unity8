import QtQuick 2.0
import Ubuntu.Components 1.1

Item {
    id: appsFeed

    property var feedManager: null

    signal applicationLaunched(string appId)

    Image {
        anchors.fill: parent
        source: "graphics/paper_portrait.png"
    }

    Item {
        id: dashGrid
        width: parent.width
        implicitHeight: grid.height + units.gu(4)

        Grid {
            id: grid
            anchors.centerIn: parent
            rows: 3
            columns: 3
            spacing: units.gu(4)
            Repeater {
                model: feedManager.dashFakeAppsModel
                Item {
                    width: childrenRect.width
                    height: childrenRect.height
                    UbuntuShape {
                        id: appIcon
                        width: units.gu(8)
                        height: units.gu(7.5)
                        color: "white"
                        radius: "medium"
                        image: Image {
                            sourceSize.width: units.gu(8)
                            sourceSize.height: units.gu(7.5)
                            source: "graphics/" + appIcon_m
                        }
                    }
                    Label {
                        id: appIconText
                        text: appName_m
                        color: "black"
                        fontSize: "small"
                        anchors {
                            horizontalCenter: appIcon.horizontalCenter
                            top: appIcon.bottom
                            topMargin: units.gu(1)
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: appsFeed.applicationLaunched(appId_m)
                    }
                }
            }
        }
    }
}
