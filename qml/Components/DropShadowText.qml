import QtQuick 2.0
import Ubuntu.Components 1.1
import QtGraphicalEffects 1.0 

Item {
    id: root
    property alias clip: label.clip
    property alias color: label.color
    property alias elide: label.elide
    property alias font: label.font
    property alias fontSize: label.fontSize
    property alias text: label.text
    property alias textFormat: label.textFormat
    property alias wrapMode: label.wrapMode
    property alias horizontalAlignment: label.horizontalAlignment
    property alias verticalAlignment: label.verticalAlignment
    property var labelWidth
    property var labelHeight
    width: label.width
    height: label.height

    Label {
        id: label
        width: labelWidth
        height: labelHeight
    }

    DropShadow {
        anchors.fill: label
        radius: 4
        samples: 8
        color: "#80000000"
        source: label
    }
}
