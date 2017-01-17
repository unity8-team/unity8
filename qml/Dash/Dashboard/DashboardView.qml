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
import Utils 0.1
import "../../Components"
import ".."
import "../../Components/flickableUtils.js" as FlickableUtilsJS

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

    ScrollView {
        id: contents
        anchors {
            left: parent.left
            top: parent.top
            bottom: buttonBar.top
            right: parent.right
            topMargin: root.topMargin
            bottomMargin: root.contentSpacing
        }
        flickableItem {
            flickableDirection: Flickable.VerticalFlick
            flickDeceleration: FlickableUtilsJS.getFlickDeceleration(units.gridUnit)
            maximumFlickVelocity: FlickableUtilsJS.getMaximumFlickVelocity(units.gridUnit)
            boundsBehavior: Flickable.StopAtBounds
        }
        horizontalScrollbar.enabled: false

        DropArea {
            id: dropArea
            anchors.fill: parent

            onDropped: {
                var fromIndex = drag.source.visualIndex;
                print("DROP from:", drop.source, ", index:", fromIndex);

                function matchDelegate(obj) { return String(obj.objectName).indexOf("dashboardDelegate") >= 0 &&
                                              obj.objectName !== drag.source.objectName; }
                var delegateAtCenter = Functions.itemAt(journal.view, drop.x, drop.y, matchDelegate);

                var toIndex = delegateAtCenter ? delegateAtCenter.visualIndex : fromIndex;
                print("Dropped on", delegateAtCenter, ", index:", toIndex);

                fakeModel.move(fromIndex, toIndex, 1);
                journal.moveDelegate(fromIndex, toIndex);

                if (delegateAtCenter) {
                    drop.acceptProposedAction();
                }
            }
        }

        ResponsiveVerticalJournal {
            id: journal
            width: contents.width

            model: fakeModel
            rowSpacing: root.contentSpacing
            minimumColumnSpacing: root.contentSpacing
            columnWidth: (contents.width - root.leftMargin*2 - contents.verticalScrollbar.width) / root.columnCount

            delegate: DashboardDelegate {
                editMode: root.editMode
                width: parent.columnWidth

                onClose: {
                    print("Closing index:", index)
                    fakeModel.remove(index, 1);
                }
            }
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
            id: btnLocation
            text: i18n.tr("Edit location")
            visible: root.editMode
        }

        Button {
            id: btnAddMore
            text: i18n.tr("Add more sources")
            //iconName: "add" // FIXME screws the button width and the whole layout
            iconPosition: "right"
            visible: root.editMode
        }

        Item { // horizontal spacer
            Layout.fillWidth: true
        }

        Button {
            id: btnEditDone
            text: root.editMode ? i18n.tr("Done") : i18n.tr("Edit")
            onClicked: root.editMode = !root.editMode;
            //onClicked: fakeModel.move(0, 1, 1); // exchange 0 and 1
        }
    }
}
