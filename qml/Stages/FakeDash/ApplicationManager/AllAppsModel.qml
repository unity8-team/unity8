import QtQuick 2.0

ListModel {
    id: allFeedsModel
    ListElement {
        feedName: "App1"
        installed: true
    }
    ListElement {
        feedName: "App2"
        installed: true
    }
    ListElement {
        feedName: "App3"
        installed: true
    }
    ListElement {
        feedName: "App4"
        installed: true
    }
    ListElement {
        feedName: "App5"
        installed: false
    }
}
