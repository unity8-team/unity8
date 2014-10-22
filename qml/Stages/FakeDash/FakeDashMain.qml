import QtQuick 2.0
import Ubuntu.Components 1.1
import "Dash"
import "ApplicationManager"
/*!
    \brief MainView with a Label and Button elements.
*/

Item {
    id: fakeDashRoot

    property alias applicationManager: applicationManager


    // Note! applicationName needs to match the "name" field of the click manifest
    //applicationName: "com.ubuntu.developer.vesar.phonenavigationwithfeedsasapps"

    /*
     This property enables the application to change orientation
     when the device is rotated. The default is false.
    */
    //automaticOrientation: true

    // Removes the old toolbar and enables new features of the new header.
    //useDeprecatedToolbar: false

    property bool tablet: false
    width: tablet ? units.gu(160) : units.gu(40)
    height: tablet ? units.gu(100) : units.gu(71)

    focus: true
    Keys.onPressed: {
        if (event.key == Qt.Key_D) {
            applicationManager.printDashModel()
        } else if (event.key == Qt.Key_M)  {
            applicationManager.printManageDashModel()
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: "black"
    }

    Dash {
        id: dash
        anchors.fill: parent
        dashModel: applicationManager.dashModel
        manageDashModel: applicationManager.manageDashModel
    }

    ApplicationManager {
        id: applicationManager
    }
}

