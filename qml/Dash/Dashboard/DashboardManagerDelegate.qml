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
import Ubuntu.Components 1.3
import "../../Components"
import ".."

ListItem {
    id: root
    objectName: name + "Section"

    signal requestFavorite(string scopeId, bool favorite)

    // Expose for testing
    readonly property int index: model.index

    implicitHeight: layout.height
    divider.visible: false

    Item {
        id: layout

        height: categoryView.contentHeight
        width: parent.width

        ListView {
            id: categoryView
            objectName: "categoryView"

            readonly property bool isPinnedToDashboard: categoryId === "favorites"
            readonly property bool isAlsoInstalled: categoryId === "other"

            height: contentHeight
            width: parent.width

            model: results
            header: DashSectionHeader {
                visible: results.count > 0
                text: {
                    if (name === "Favorites") {
                        return i18n.tr("Dashboard");
                    } else if (name === "Non Favorites") {
                        return i18n.tr("Also Installed");
                    } else {
                        return name;
                    }
                }
            }

            delegate: ListItem {
                readonly property alias innerLayoutPadding: innerLayout.padding

                height: innerLayout.height
                width: parent.width

                divider.visible: false

                Rectangle {
                    height: units.dp(1); width: parent.width
                    color: theme.palette.normal.raisedText
                    anchors.top: parent.top

                    visible: index != 0
                }

                ListItemLayout {
                    id: innerLayout
                    objectName: "layout" + index

                    UbuntuShape {
                        height: units.gu(4.67)
                        width: units.gu(4.67)
                        SlotsLayout.position: SlotsLayout.Leading
                        source: Image {
                            anchors.fill: parent
                            source: "../" + model.art
                        }
                    }

                    title.text: model.scopeId

                    // FIXME: update when pin icon is added to theme
                    Image {
                        objectName: "pinIcon"

                        height: units.gu(2)
                        width: units.gu(2)
                        fillMode: Image.PreserveAspectFit
                        source: {
                            if (categoryView.isPinnedToDashboard) {
                                return "graphics/pinned.png"
                            } else if (categoryView.isAlsoInstalled) {
                                return "graphics/unpinned.png"
                            } else {
                                return ""
                            }
                        }

                        MouseArea {
                            objectName: "favoriteButton"

                            anchors.fill: parent
                            onClicked: {
                                root.requestFavorite(model.scopeId, !categoryView.isPinnedToDashboard)
                            }
                        }
                    }
                }
            }
        }
    }
}
