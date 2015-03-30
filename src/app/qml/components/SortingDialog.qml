import QtQuick 2.2
import Ubuntu.Components 1.0
import Ubuntu.Components.Popups 1.0
import Ubuntu.Components.ListItems 1.0
import reminders 1.0

Item {
    id: root

    property int sortOrder

    signal accepted();

    Component.onCompleted: PopupUtils.open(dialogComponent, root, {sortOrder: root.sortOrder})

    Component {
        id: dialogComponent
        Dialog {
            id: dialog
            title: i18n.tr("Sort by")

            property alias sortOrder: optionSelector.selectedIndex


            OptionSelector {
                id: optionSelector
                expanded: true
                model: [
                    i18n.tr("Date created (newest first)"),
                    i18n.tr("Date created (oldest first)"),
                    i18n.tr("Date updated (newest first)"),
                    i18n.tr("Date updated (oldest first)"),
                    i18n.tr("Title (ascending)"),
                    i18n.tr("Title (descending)")
                ]

                onDelegateClicked: {
                    root.sortOrder = index
                    root.accepted();
                    PopupUtils.close(dialog);
                }
            }
        }
    }
}

