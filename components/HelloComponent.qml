import QtQuick 2.0
import Ubuntu.Components 0.1

UbuntuShape {
    width: 200
    height: width

    property alias text : myText.text

    Label {
        id: myText
        anchors.centerIn: parent
    }
}
