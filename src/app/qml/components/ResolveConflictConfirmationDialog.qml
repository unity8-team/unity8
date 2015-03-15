/*
 * Copyright: 2015 Canonical, Ltd
 *
 * This file is part of reminders
 *
 * reminders is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.2
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0

Dialog {
    id: root
    title: i18n.tr("Resolve conflict")
    text: {
        var fullText;
        if (keepLocal) {
            if (remoteDeleted) {
                fullText = i18n.tr("This will <b>keep the changes made on this device</b> and <b>restore the note on Evernote</b>.");
            } else if (localDeleted) {
                fullText = i18n.tr("This will <b>delete the changed note on Evernote</b>.");
            } else {
                fullText = i18n.tr("This will <b>keep the changes made on this device</b> and <b>discard any changes made on Evernote</b>.");
            }
        } else {
            if (remoteDeleted) {
                fullText = i18n.tr("This will <b>delete the changed note on this device</b>.");
            } else if (localDeleted) {
                fullText = i18n.tr("This will <b>download the changed note from Evernote</b> and <b>restore it on this device</b>.");
            } else {
                fullText = i18n.tr("This will <b>download the changed note from Evernote</b> and <b>discard any changes made on this device</b>.");
            }
        }
        fullText += "<br><br>" + i18n.tr("Are you sure you want to continue?");
        return fullText;
    }

    property bool keepLocal: true
    property bool remoteDeleted: false
    property bool localDeleted: false

    signal accepted();
    signal rejected();

    Button {
        text: i18n.tr("Yes")
        color: UbuntuColors.green
        onClicked: {
            root.accepted();
            PopupUtils.close(root);
        }
    }

    Button {
        text: i18n.tr("No")
        color: UbuntuColors.red
        onClicked: {
            root.rejected();
            PopupUtils.close(root)
        }
    }
}
