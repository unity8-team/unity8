import QtQuick 2.4
import Ubuntu.Components 1.3
import ".."

ListItem {
    id: root
    objectName: name + "Section"

    signal requestFavorite(string scopeId, bool favorite)

    height: layout.height + (divider.visible ? divider.height : 0)
    width: parent.width

    readonly property int index: model.index

    divider.visible: results.count > 0
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
                height: innerLayout.height + (divider.visible ?
                                              divider.height : 0)
                width: parent.width

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

