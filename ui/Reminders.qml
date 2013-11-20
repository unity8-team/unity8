import QtQuick 2.0
import Ubuntu.Components 0.1

Page {
    id: remindersPage

    Label {
        id: developmentWarning
        anchors.centerIn: parent
        text: i18n.tr("This page is still in development")
    }
}
