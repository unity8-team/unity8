/*
 * Copyright 2016 Canonical Ltd.
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
 * Authored by Jonas G. Drange <jonas.drange@canonical.com>
 */

import QtQuick 2.4
import QtQuick.Layouts 1.2
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.Settings.Components 0.1
import Ubuntu.Settings.Fingerprint 0.1

MainView {
    width: units.gu(50)
    height: units.gu(90)

    Item {
        z: 1
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: units.gu(2)
            bottomMargin: units.gu(7)
        }

        height: childrenRect.height
        width: childrenRect.width

        Button {
            text: i18n.tr("Tools…")
            color: UbuntuColors.orange
            onClicked: PopupUtils.open(tools)
        }
    }

    PageStack {
        id: pageStack

        Component.onCompleted: push(fingerprintPage, {
            plugin: p
        })

        // Example plugin
        QtObject {
            id: p
            property int fingerprintCount: 0
            property bool passcodeSet: false

            signal enrollmentProgressed(double progress)
            signal enrollmentCompleted()

            // 0: finger left thing before it was finished
            // 1: some unrecoverable error
            signal enrollmentFailed(int error)
        }

        Component {
            id: fingerprintPage
            Fingerprint {
                onRequestPasscode: p.passcodeSet = !p.passcodeSet
            }
        }
    }

    Component {
        id: tools

        Dialog {
            id: toolsDiag
            title: i18n.tr("Example tools")

            Column {
                ListItems.Standard {
                    text: "Enrollment stopped"
                    onClicked: {
                        p.enrollmentFailed(0);
                        PopupUtils.close(toolsDiag);
                    }
                }
                ListItems.Standard {
                    text: "Enrollment started"
                    onClicked: {
                        p.enrollmentProgressed(0.1);
                        PopupUtils.close(toolsDiag);
                    }
                }
                ListItems.Standard {
                    text: "Enrollment interrupted"
                    onClicked: {
                        p.enrollmentFailed(0);;
                        PopupUtils.close(toolsDiag);
                    }
                }
                ListItems.Standard {
                    text: "Enrolled 0%"
                    onClicked: {
                        p.enrollmentProgressed(0.0);
                        PopupUtils.close(toolsDiag);
                    }
                }
                ListItems.Standard {
                    text: "Enrolled 25%"
                    onClicked: {
                        p.enrollmentProgressed(0.25);
                        PopupUtils.close(toolsDiag);
                    }
                }
                ListItems.Standard {
                    text: "Enrolled 50%"
                    onClicked: {
                        p.enrollmentProgressed(0.5);
                        PopupUtils.close(toolsDiag);
                    }
                }
                ListItems.Standard {
                    text: "Enrolled 75%"
                    onClicked: {
                        p.enrollmentProgressed(0.75);
                        PopupUtils.close(toolsDiag);
                    }
                }
                ListItems.Standard {
                    text: "Enrolled 100%"
                    onClicked: {
                        p.enrollmentProgressed(1);
                        PopupUtils.close(toolsDiag);
                    }
                }
                ListItems.Standard {
                    text: "Enrollment done"
                    onClicked: {
                        p.enrollmentCompleted();
                        PopupUtils.close(toolsDiag);
                    }
                }
                ListItems.Standard {
                    text: "Enrollment failed"
                    onClicked: {
                        p.enrollmentFailed(1);
                        PopupUtils.close(toolsDiag);
                    }
                }
                ListItems.Standard {
                    text: "Toggle passcode"
                    onClicked: {
                        p.passcodeSet = !p.passcodeSet;
                        PopupUtils.close(toolsDiag);
                    }
                }
                ListItems.Standard {
                    text: "Add fingerprint"
                    onClicked: {
                        p.fingerprintCount = p.fingerprintCount + 1;
                        PopupUtils.close(toolsDiag);
                    }
                }
                ListItems.Standard {
                    text: "Remove fingerprint"
                    onClicked: {
                        p.fingerprintCount = Math.max(0, p.fingerprintCount - 1);
                        PopupUtils.close(toolsDiag);
                    }
                }
            }
        }
    }
}
