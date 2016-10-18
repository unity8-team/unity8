/*
 * Copyright (C) 2013,2015,2016 Canonical, Ltd.
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
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3
import Utils 0.1
import "../Components"

Item {
    id: root
    objectName: "pageHeader"
    implicitHeight: headerContainer.height + signatureLineHeight
    readonly property real signatureLineHeight: showSignatureLine ? units.gu(2) : 0
    readonly property real headerDividerLuminance: Style.luminance(bottomBorder.color)

    property alias extraPanelHeight: searchHeaderContents.extraPanelHeight
    property alias searchContents: searchHeaderContents
    property alias searchTextField: searchHeaderContents.searchTextField

    property bool backIsClose: false
    property bool favorite: false
    property bool favoriteEnabled: false
    property bool searchEntryEnabled: false
    property bool settingsEnabled: false
    property bool showBackButton: false
    property bool showSignatureLine: true
    property bool storeEntryEnabled: false

    property int activeFiltersCount: 0
    property int paginationCount: 0
    property int paginationIndex: -1

    property ListModel searchHistory

    property string navigationTag
    property string searchQuery
    property string title

    property var categoryView
    property var scope
    property var scopeStyle: null
    property var scopeView
    property var searchHint: searchTextField.placeholderText

    signal backClicked()
    signal clearSearch(bool keepPanelOpen)
    signal favoriteClicked()
    signal searchTextFieldFocused()
    signal settingsClicked()
    signal showFiltersPopup(var item)
    signal storeClicked()

    onScopeStyleChanged: refreshLogo()
    onSearchQueryChanged: {
        // Make sure we are at the search page if the search query changes behind our feet
        if (searchQuery) {
            headerContainer.showSearch = true;
        }
    }
    onNavigationTagChanged: {
        // Make sure we are at the search page if the navigation tag changes behind our feet
        if (navigationTag) {
            headerContainer.showSearch = true;
        }
    }

    function triggerSearch() {
        if (searchEntryEnabled) {
            headerContainer.showSearch = true;
            searchTextField.forceActiveFocus();
        }
    }

    function resetSearch() {
        searchHeaderContents.resetSearch();
    }

    function refreshLogo() {
        if (root.scopeStyle ? root.scopeStyle.headerLogo != "" : false) {
            header.contents = imageComponent.createObject();
        } else if (header.contents) {
            header.contents.destroy();
            header.contents = null;
        }
    }

    function unfocus(keepSearch) {
        searchHeaderContents.unfocus(keepSearch);
    }

    Binding {
        target: searchHeaderContents.searchTextField
        property: "text"
        value: root.searchQuery
    }

    Connections {
        target: root.scopeStyle
        onHeaderLogoChanged: root.refreshLogo()
    }

    InverseMouseArea {
        anchors {
            fill: parent
            margins: units.gu(1)
            bottomMargin: units.gu(3) + extraPanelHeight
        }

        visible: headerContainer.showSearch
        onPressed: {
            searchHeaderContents.closePopup(/* keepFocus */false);
            mouse.accepted = false;
        }
    }

    Rectangle {
        id: bottomBorder
        visible: showSignatureLine
        anchors {
            top: headerContainer.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        color: root.scopeStyle ? root.scopeStyle.headerDividerColor : "#e0e0e0"

        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: units.dp(1)
            color: Qt.darker(parent.color, 1.1)
        }
    }

    Row {
        visible: bottomBorder.visible
        spacing: units.gu(.5)
        Repeater {
            objectName: "paginationRepeater"
            model: root.paginationCount
            Image {
                objectName: "paginationDots_" + index
                height: units.gu(1)
                width: height
                source: (index == root.paginationIndex) ? "graphics/pagination_dot_on.png" : "graphics/pagination_dot_off.png"
            }
        }
        anchors {
            top: headerContainer.bottom
            horizontalCenter: headerContainer.horizontalCenter
            topMargin: units.gu(.5)
        }
    }

    Item {
        id: headerContainer
        objectName: "headerContainer"
        anchors { left: parent.left; top: parent.top; right: parent.right }
        height: header.__styleInstance.contentHeight

        property bool showSearch: false

        state: headerContainer.showSearch ? "search" : ""

        states: State {
            name: "search"

            AnchorChanges {
                target: headersColumn
                anchors.top: parent.top
                anchors.bottom: undefined
            }
        }

        transitions: Transition {
            id: openSearchAnimation
            AnchorAnimation {
                duration: UbuntuAnimation.FastDuration
                easing: UbuntuAnimation.StandardEasing
            }

            property bool openPopup: false

            onRunningChanged: {
                headerContainer.clip = running;
                if (!running && openSearchAnimation.openPopup) {
                    openSearchAnimation.openPopup = false;
                    root.openPopup();
                }
            }
        }

        Background {
            id: background
            objectName: "headerBackground"
            style: scopeStyle.headerBackground
        }

        Column {
            id: headersColumn
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            PageHeader {
                id: searchHeader
                anchors { left: parent.left; right: parent.right }
                opacity: headerContainer.clip || headerContainer.showSearch ? 1 : 0 // setting visible false cause column to relayout

                StyleHints {
                    foregroundColor: root.scopeStyle ? root.scopeStyle.headerForeground : theme.palette.normal.baseText
                    backgroundColor: "transparent"
                    dividerColor: "transparent"
                }

                contents: SearchHeaderContents {
                    id: searchHeaderContents
                    objectName: "searchHeaderContents"

                    anchors.fill: parent

                    activeFiltersCount: root.activeFiltersCount
                    categoryView: root.categoryView
                    extraPanelYOffset: root.signatureLineHeight
                    navigationTag: root.navigationTag
                    scope: root.scope
                    scopeView: root.scopeView
                    searchHistory: root.searchHistory

                    // PageHeader adds margins and that throws off the width
                    parentWidth: root.width
                    onCancelSearch: headerContainer.showSearch = showSearch;
                    onSearchTextFieldFocused: root.searchTextFieldFocused();

                    Binding {
                        target: root
                        property: "searchQuery"
                        value: searchTextField.text
                    }
                }
            }

            PageHeader {
                id: header
                objectName: "innerPageHeader"
                anchors { left: parent.left; right: parent.right }
                height: headerContainer.height
                opacity: headerContainer.clip || !headerContainer.showSearch ? 1 : 0 // setting visible false cause column to relayout
                title: root.title

                StyleHints {
                    foregroundColor: root.scopeStyle ? root.scopeStyle.headerForeground : theme.palette.normal.baseText
                    backgroundColor: "transparent"
                    dividerColor: "transparent"
                }

                leadingActionBar.actions: Action {
                    iconName: backIsClose ? "close" : "back"
                    visible: root.showBackButton
                    onTriggered: root.backClicked()
                }

                trailingActionBar {
                    actions: [
                        Action {
                            objectName: "store"
                            text: i18n.ctr("Button: Open the Ubuntu Store", "Store")
                            iconName: "ubuntu-store-symbolic"
                            visible: root.storeEntryEnabled
                            onTriggered: root.storeClicked();
                        },
                        Action {
                            objectName: "search"
                            text: i18n.ctr("Button: Start a search in the current dash scope", "Search")
                            iconName: "search"
                            visible: root.searchEntryEnabled
                            onTriggered: {
                                headerContainer.showSearch = true;
                                searchTextField.forceActiveFocus();
                            }
                        },
                        Action {
                            objectName: "settings"
                            text: i18n.ctr("Button: Show the current dash scope settings", "Settings")
                            iconName: "settings"
                            visible: root.settingsEnabled
                            onTriggered: root.settingsClicked()
                        },
                        Action {
                            objectName: "favorite"
                            text: root.favorite ? i18n.tr("Remove from Favorites") : i18n.tr("Add to Favorites")
                            iconName: root.favorite ? "starred" : "non-starred"
                            visible: root.favoriteEnabled
                            onTriggered: root.favoriteClicked()
                        }
                    ]
                }

                Component.onCompleted: root.refreshLogo()

                Component {
                    id: imageComponent

                    Item {
                        anchors { fill: parent; topMargin: units.gu(1.5); bottomMargin: units.gu(1.5) }
                        clip: true
                        Image {
                            objectName: "titleImage"
                            anchors.fill: parent
                            source: root.scopeStyle ? root.scopeStyle.headerLogo : ""
                            fillMode: Image.PreserveAspectFit
                            horizontalAlignment: Image.AlignLeft
                            sourceSize.height: height
                        }
                    }
                }
            }
        }
    }

    // FIXME this doesn't work with solid scope backgrounds due to z-ordering
    Item {
        id: bottomHighlight
        visible: bottomBorder.visible
        anchors {
            top: parent.bottom
            left: parent.left
            right: parent.right
        }
        z: 1
        height: units.dp(1)
        opacity: 0.6

        Rectangle {
            anchors.fill: parent
            color: if (root.scopeStyle) {
                       Qt.lighter(Qt.rgba(root.scopeStyle.background.r,
                                          root.scopeStyle.background.g,
                                          root.scopeStyle.background.b, 1.0), 1.2);
                   } else "#CCFFFFFF"
        }
    }
}
