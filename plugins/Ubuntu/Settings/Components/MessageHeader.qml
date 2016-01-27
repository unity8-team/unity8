/*
 * Copyright 2013 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 *      Renato Araujo Oliveira Filho <renato@canonical.com>
 *      Olivier Tilloy <olivier.tilloy@canonical.com>
 */

import QtQuick 2.1
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1

Item {
    id: messageHeader

    property alias avatar: avatarImage.source
    property alias icon: iconImage.source
    property alias title: titleText.text
    property alias time: timeText.text
    property alias body: bodyText.text

    signal iconClicked()

    implicitHeight: layout.height

    function shakeIcon() {
        shake.restart();
    }

    RowLayout {
        id: layout
        anchors {
            left: parent.left
            right: parent.right
            rightMargin: units.gu(4)
        }
        spacing: units.gu(2)

        UbuntuShapeForItem {
            Layout.preferredWidth: units.gu(6)
            Layout.preferredHeight: units.gu(6)

            image: avatarImage
            Icon {
                id: avatarImage
                objectName: "avatar"

                color: {
                    if (String(source).match(/^image:\/\/theme/)) {
                        return theme.palette.normal.backgroundText;
                    }
                    return Qt.rgba(0.0, 0.0, 0.0, 0.0);
                }
            }
        }

        ColumnLayout {
            Label {
                id: titleText
                objectName: "title"

                maximumLineCount: 1
                elide: Text.ElideRight
                font.weight: Font.DemiBold
                fontSize: "medium"

                Layout.fillWidth: true
                // calculate width with regard to the time's incursion into this layout's space.
                Layout.maximumWidth: layout.width - timeLayout.width - units.gu(4)
            }
            spacing: units.gu(0.5)

            Label {
                id: bodyText
                objectName: "body"

                maximumLineCount: 3
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                fontSize: "small"

                Layout.fillWidth: true
            }
        }
    }

    ColumnLayout {
        id: timeLayout
        anchors.right: parent.right

        Label {
            id: timeText
            objectName: "time"
            anchors.right: parent.right

            fontSize: "x-small"
            maximumLineCount: 1
        }
        spacing: units.gu(0.5)

        Icon {
            id: iconImage
            objectName: "icon"
            Layout.preferredHeight: units.gu(3)
            Layout.preferredWidth: units.gu(3)
            Layout.alignment: Qt.AlignRight
            color: theme.palette.normal.backgroundText

            MouseArea {
                anchors.fill: parent
                onClicked: messageHeader.iconClicked()
            }

            SequentialAnimation {
                id: shake
                PropertyAnimation { target: iconImage; property: "rotation"; duration: 50; to: -20 }
                SpringAnimation { target: iconImage; property: "rotation"; from: -20; to: 0; mass: 0.5; spring: 15; damping: 0.1 }
            }
        }
    }
}
