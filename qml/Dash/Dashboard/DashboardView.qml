/*
 * Copyright (C) 2017 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import QtQuick.Layouts 1.2
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3
import "../../Components"
import ".."

StyledItem {
    id: root
    objectName: "dashboard"

    property bool editMode: false
    property int columnCount: 3

    readonly property int leftMargin: units.gu(3)
    readonly property int topMargin: units.gu(3)
    readonly property int contentSpacing: units.gu(1)

    theme: ThemeSettings {
        name: "Ubuntu.Components.Themes.Ambiance"
    }

    ListModel {
        id: fakeModel
        ListElement { name: "Weather"; headerColor: "yellow" }
        ListElement { name: "BBC News"; headerColor: "red"  }
        ListElement { name: "Fitbit"; headerColor: "teal"  }
        ListElement { name: "The Guardian"; headerColor: "blue"  }
        ListElement { name: "Telegram"; headerColor: "navy"  }
        ListElement { name: "Clock"; content: "Qt.formatTime(new Date())"; ttl: 1000 }
        ListElement { name: "G" }
        ListElement { name: "H" }
        ListElement { name: "I" }
        ListElement { name: "J" }
        ListElement { name: "K" }
        ListElement { name: "L" }
        ListElement { name: "M" }
        ListElement { name: "N" }
        ListElement { name: "O" }
        ListElement { name: "P" }
        ListElement { name: "Q" }
        ListElement { name: "R" }
        ListElement { name: "S" }
        ListElement { name: "T" }
        ListElement { name: "U" }
    }

    Component {
        id: dashboardViewContentsComponent
        DashboardViewContents {
            model: fakeModel
            editMode: root.editMode
            columnCount: root.columnCount
            contentSpacing: root.contentSpacing
        }
    }

    Component {
        id: dashboardViewLocationComponent
        DashboardViewLocation {
            contentSpacing: root.contentSpacing
        }
    }

    Loader {
        id: loader
        active: true
        asynchronous: true
        visible: status === Loader.Ready
        anchors {
            left: parent.left
            top: parent.top
            bottom: buttonBar.top
            right: parent.right
            leftMargin: root.leftMargin
            rightMargin: root.leftMargin
            topMargin: root.topMargin
            bottomMargin: root.contentSpacing
        }
    }

    RowLayout {
        id: buttonBar
        spacing: root.contentSpacing
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: root.leftMargin
            rightMargin: root.leftMargin
            topMargin: root.contentSpacing
            bottomMargin: root.contentSpacing
        }

        Button {
            id: btnLocationBack
        }

        Button {
            id: btnSources
            //iconName: "add" // FIXME icon screws the button width and the whole layout
            //iconPosition: "right"
        }

        Item { // horizontal spacer
            Layout.fillWidth: true
        }

        Button {
            id: btnEdit
        }
    }

    state: "dashboard"
    states: [
        State {
            name: "dashboard"
            when: !root.editMode
            PropertyChanges { target: loader; sourceComponent: dashboardViewContentsComponent }
            PropertyChanges { target: btnEdit; text: i18n.tr("Edit"); onClicked: root.editMode = true; }
            PropertyChanges { target: btnLocationBack; visible: false }
            PropertyChanges { target: btnSources; visible: false }
        },
        State {
            name: "edit"
            extend: "dashboard"
            when: root.editMode
            PropertyChanges { target: btnEdit; visible: true; text: i18n.tr("Done"); onClicked: root.editMode = false; }
            PropertyChanges { target: btnLocationBack; visible: true; text: root.columnCount == 1 ? i18n.tr("Location...") : i18n.tr("Edit location");
                onClicked: root.state = "location";
            }
            PropertyChanges { target: btnSources; visible: true; text: root.columnCount == 1 ? i18n.tr("Add...") : i18n.tr("Add more sources ➕");
                onClicked: root.state = "sources";
            }
        },
        State {
            name: "sources"
            extend: "edit"
            PropertyChanges { target: loader; sourceComponent: undefined } // TODO
            PropertyChanges { target: btnLocationBack; text: i18n.tr("Back"); onClicked: root.editMode = false; }
            PropertyChanges { target: btnSources; visible: false }
            PropertyChanges { target: btnEdit; visible: false }
        },
        State {
            name: "location"
            extend: "edit"
            PropertyChanges { target: loader; sourceComponent: dashboardViewLocationComponent }
            PropertyChanges { target: btnLocationBack; text: i18n.tr("Back"); onClicked: root.editMode = false; }
            PropertyChanges { target: btnSources; visible: false }
            PropertyChanges { target: btnEdit; visible: false }
        }
    ]
}
