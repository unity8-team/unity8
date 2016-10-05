/*
 * Copyright (C) 2016 Canonical, Ltd.
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

Item {
    id: root

    property int activeFiltersCount
    property string navigationTag

    property ListModel searchHistory
    property var categoryView
    property var scope
    property var scopeView

    readonly property alias searchTextField: searchTextField
    readonly property bool extraPanelVisible: pageHeaderExtraPanel.visible
    readonly property bool scopeHasFilters: typeof(scope) !== "undefined" && scope &&  scope.filters != null ? true : false // Prevent warning
    readonly property real extraPanelHeight: extraPanelVisible ?
                           pageHeaderExtraPanel.height : 0

    // For testing only!
    readonly property alias thePopover: d.extraPanelPopover

    signal cancelSearch(bool showSearch);
    signal searchTextFieldFocused();

    state: "noExtraPanel"
    states: [
        State {
            name: "noExtraPanel"
        },

        State {
            name: "yesExtraPanel"

            ParentChange {
                target: pageHeaderExtraPanel
                parent: d.extraPanelPopover
            }

            PropertyChanges {
                target: pageHeaderExtraPanel
                visible: true
            }
        }
    ]

    function clearSearch(keepPanelOpen) {
        resetSearch();
        if (typeof(scope) !== "undefined") scope.resetPrimaryNavigationTag();
        if (root.pageHeaderExtraPanel) {
            root.pageHeaderExtraPanel.resetNavigation();
        }

        if ((root.extraPanelVisible || searchHistory.count > 0) && keepPanelOpen) {
            root.showExtraPanel();
        } else {
            root.hideExtraPanel();
        }
    }

    function closePopup(keepFocus, keepSearch) {
        root.hideExtraPanel();
        if (!keepFocus) {
            unfocus(keepSearch);
        }

        if (!keepSearch && !searchTextField.text &&
            !root.navigationTag && searchHistory.count === 0) {
            root.cancelSearch(false);
        }
    }

    function dashNavigationLeafClicked() {
        root.closePopup();
        categoryView.pageHeader.unfocus();
    }

    function resetSearch() {
        if (root.searchHistory) {
            root.searchHistory.addQuery(searchTextField.text);
        }
        searchTextField.text = "";
        cancelSearch(false);
        closePopup(true);
    }

    function unfocus(keepSearch) {
        searchTextField.focus = false;
        if (!keepSearch && !searchTextField.text && !root.navigationTag) {
            root.cancelSearch(false);
        }
    }

    function showFiltersPopup(popupParent) {
        var url = Qt.resolvedUrl("FiltersPopover.qml");

        root.hideExtraPanel();
        scopeView.filtersPopover = PopupUtils.open(url, popupParent, {
            "contentWidth" : Qt.binding(function() {
                return scopeView.width - units.gu(2);
            })}
        );

        scopeView.filtersPopover.Component.onDestruction.connect(
            function() {
                root.closePopup(false);
            }
        );
    }

    function hideExtraPanel() {
        state = "noExtraPanel"

        if (!root.extraPanelVisible) return;
        PopupUtils.close(d.extraPanelPopover);
    }

    function showExtraPanel() {
        state = "yesExtraPanel"

        if (root.extraPanelVisible) return;
        d.extraPanelPopover = PopupUtils.open(extraPanelComponent, root);
    }

    QtObject {
        id: d

        property var extraPanelPopover
    }

    Keys.onEscapePressed: { // clear the search text, dismiss the search in the second step
        if (searchTextField.text != "") {
            root.clearSearch(true);
            root.cancelSearch(false);
        } else {
            root.clearSearch(false);
        }
    }

    // The extra panel lives outside the popover so that its state can be read
    // even if the popover is closed (or has never been opened).
    // This also allows positioning things differently in the future.
    PageHeaderExtraPanel {
        id: pageHeaderExtraPanel
        objectName: "extraPanel"

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width >= units.gu(60) ? units.gu(40) : parent.width
        windowHeight: typeof(scopeView) !== "undefined" ? scopeView.height : 0
        visible: false

        scope: root.scope
        searchHistory: root.searchHistory

        onDashNavigationLeafClicked: root.dashNavigationLeafClicked();

        onExtraPanelOptionSelected: {
            root.closePopup();
            categoryView.pageHeader.unfocus();
        }

        onHistoryItemClicked: {
            searchHistory.addQuery(text);
            searchTextField.text = text;
            root.unfocus(false);
        }
    }

    Component {
        id: extraPanelComponent

        Popover {
            id: extraPanelPopover
            objectName: "extraPanelPlaceholder"

            readonly property real yOffset: {
                if (typeof(categoryView) !== "undefined") {
                    return root.categoryView.pageHeader.height -
                           root.categoryView.pageHeader.signatureLineHeight;
                } else {
                    return 0;
                }
            }

            function maintainOffset() {
                if (y != yOffset)
                    y = yOffset;
            }

            autoClose: false

            // The popover likes to jump around, hold it still.
            Component.onCompleted: maintainOffset();
            onYChanged: maintainOffset();
        }
    }

    TextField {
        id: searchTextField

        objectName: "searchTextField"
        inputMethodHints: Qt.ImhNoPredictiveText
        hasClearButton: false
        anchors {
            top: parent.top
            topMargin: units.gu(1)
            left: parent.left
            bottom: parent.bottom
            bottomMargin: units.gu(1)
            right: settingsButton.left
            rightMargin: settingsButton.visible ? 0 : units.gu(2)
        }

        primaryItem: Rectangle {
            color: "#F5F4F5"
            width: root.navigationTag != "" ? tagLabel.width + units.gu(2) : 0
            height: root.navigationTag != "" ? tagLabel.height + units.gu(1) : 0
            radius: units.gu(0.5)
            Label {
                id: tagLabel
                text: root.navigationTag
                anchors.centerIn: parent
                color: "#333333"
            }
        }

        secondaryItem: AbstractButton {
            id: clearButton
            height: searchTextField.height
            width: height
            enabled: searchTextField.text.length > 0 || root.navigationTag != ""

            Image {
                objectName: "clearIcon"
                anchors.fill: parent
                anchors.margins: units.gu(1)
                source: "image://theme/clear"
                opacity: parent.enabled
                visible: opacity > 0
                Behavior on opacity {
                    UbuntuNumberAnimation { duration: UbuntuAnimation.FastDuration }
                }
            }

            onClicked: {
                root.clearSearch(true);
            }
        }

        onActiveFocusChanged: {
            if (activeFocus) {
                root.searchTextFieldFocused();
                root.showExtraPanel();
            }
        }

        onTextChanged: {
            if (text != "") {
                root.closePopup(/* keepFocus */true);
            }
        }
    }

    AbstractButton {
        id: settingsButton
        objectName: "settingsButton"

        width: root.scopeHasFilters ? height : 0
        visible: width > 0

        anchors {
            top: parent.top
            right: cancelButton.left
            bottom: parent.bottom
            rightMargin: units.gu(-1)
        }

        Icon {
            anchors.fill: parent
            anchors.margins: units.gu(2)
            name: "filters"
            color: root.activeFiltersCount > 0 ? theme.palette.normal.positive : header.__styleInstance.foregroundColor
        }

        onClicked: {
            root.showFiltersPopup(settingsButton);
        }
    }

    AbstractButton {
        id: cancelButton
        objectName: "cancelButton"
        width: cancelLabel.width + cancelLabel.anchors.rightMargin + cancelLabel.anchors.leftMargin

        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
        }

        onClicked: {
            root.clearSearch(false);
            cancelSearch(false);
            root.unfocus(false);
        }

        Label {
            id: cancelLabel
            text: i18n.tr("Cancel")
            color: header.__styleInstance.foregroundColor
            verticalAlignment: Text.AlignVCenter
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: units.gu(2)
                leftMargin: units.gu(1)
            }
        }
    }
}
