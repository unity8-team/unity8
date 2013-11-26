/*
 * Copyright: 2013 Canonical, Ltd
 *
 * This file is part of reminders-app
 *
 * reminders-app is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
//import "components"
import "ui"
import Evernote 0.1

/*!
    \brief MainView with a Label and Button elements.
*/

MainView {
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "com.ubuntu.reminders-app"

    /*
     This property enables the application to change orientation
     when the device is rotated. The default is false.
    */
    //automaticOrientation: true

    width: units.gu(50)
    height: units.gu(75)

    // Temporary background color. This can be changed to other suitable backgrounds when we get official mockup designs
    backgroundColor: UbuntuColors.coolGrey

    Component.onCompleted: {
        pagestack.push(rootTabs)
        if (NotesStore.token.length === 0) {
            pagestack.push(Qt.resolvedUrl("ui/AccountSelectorPage.qml"));
        }
    }

    PageStack {
        id: pagestack

        Tabs {
            id: rootTabs

            anchors.fill: parent

            Tab {
                title: i18n.tr("Notes")
                page: NotesPage {
                    id: notesPage
                }
            }

            Tab {
                title: i18n.tr("Notebook")
                page: NotebooksPage {
                    id: notebooksPage
                }
            }

            Tab {
                title: i18n.tr("Reminders")
                page: RemindersPage {
                    id: remindersPage
                }
            }
        }
    }
}
