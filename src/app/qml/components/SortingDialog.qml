import QtQuick 2.2
import Ubuntu.Components 1.0
import Ubuntu.Components.Popups 1.0
import Ubuntu.Components.ListItems 1.0
import reminders 1.0

Dialog {
    id: root
    title: i18n.tr("Sort by")

    signal accepted();
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
    }

    Button {
        text: i18n.tr("Close")
        onClicked: {
            root.accepted();
            PopupUtils.close(root);
        }
    }
}
