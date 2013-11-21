import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1
//import "../components"

Page {
    id: remindersPage

    Label {
        id: developmentWarning
        anchors.centerIn: parent
        text: i18n.tr("This page is still in development")
    }

    ListView {

        width: parent.width; height: parent.height

        delegate: Subtitled {
            text: '<b>Name:</b> ' + model.name
            subText: '<b>Date:</b> ' + model.date
        }

//        model: RemindersModel {}

    }

}
