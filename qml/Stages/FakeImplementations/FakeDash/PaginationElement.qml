import QtQuick 2.0
import Ubuntu.Components 1.1

Item {
    id: pagination

    property int paginationIndex: -1
    property int paginationCount: 0

    width: childrenRect.width
    height: childrenRect.height

    Row {
        spacing: units.gu(.5)
        Repeater {
            model: pagination.paginationCount
            Image {
                height: units.gu(1)
                width: height
                source: (index == pagination.paginationIndex) ? "graphics/pagination_dot_on.png" : "graphics/pagination_dot_off.png"
            }
        }
    }
}
