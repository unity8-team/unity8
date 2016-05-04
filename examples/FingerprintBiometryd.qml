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
import Biometryd 0.0

MainView {
    width: units.gu(50)
    height: units.gu(90)

    Observer {
        id: enrollmentObserver
        onStarted: {
            console.log("enrollmentObserver: started")
        }
        onCanceled: {
            console.log("enrollmentObserver: canceled")
        }
        onFailed: {
            console.log("enrollmentObserver: failed")
            p.enrollmentFailed();
        }
        onProgressed: {
            // biometryd API users can use details to receive
            // device/operation-specific information about the
            // operation. We illustrate the case of a FingerprintReader here.
            console.log("enrollmentObserver: progressed: ", percent);

            var isFingerPresent             = details[FingerprintReader.isFingerPresent]
            var hasMainClusterIdentified    = details[FingerprintReader.hasMainClusterIdentified]
            var suggestedNextDirection      = details[FingerprintReader.suggestedNextDirection]
            var masks                       = details[FingerprintReader.masks]
            var estimatedFingerSize         = details[FingerprintReader.estimatedFingerSize]
            p.enrollmentProgressed(percent, details);

            console.log("isFingerPresent:",            isFingerPresent,
                        "hasMainClusterIdentified:",   hasMainClusterIdentified,
                        "suggestedNextDirection:",     suggestedNextDirection,
                        "masks:",                      masks,
                        "estimatedFingerSize",         estimatedFingerSize);
        }
        onSucceeded: {
            console.log("enrollmentObserver: succeeded")
            p.enrollmentCompleted();
        }
    }

    Observer {
        id: sizeObserver
        onStarted: {
            console.log("sizeObserver: started")
        }
        onCanceled: {
            console.log("sizeObserver: canceled")
        }
        onFailed: {
            console.log("sizeObserver: failed")
        }
        onSucceeded: {
            console.log("sizeObserver: succeeded", result)
            p.fingerprintCount = result;
        }
    }

    Observer {
        id: clearanceObserver
        onStarted: {
            console.log("clearanceObserver: started")
        }
        onCanceled: {
            console.log("clearanceObserver: canceled")
        }
        onFailed: {
            console.log("clearanceObserver: failed")
        }
        onSucceeded: {
            console.log("clearanceObserver: succeeded")
            p.fingerprintCount = 0;
        }
    }

    UbuntuSettingsFingerprint {
        id: fp
    }

    User {
        id: user
        uid: fp.uid
    }

    PageStack {
        id: pageStack

        Component.onCompleted: push(fingerprintPage, {
            plugin: p
        })

        QtObject {
            id: p
            property var ts: Biometryd.defaultDevice.templateStore

            property var sizeOperation: null
            property var enrollmentOperation: null
            property var clearanceOperation: null

            property bool passcodeSet: true
            property int fingerprintCount: 0

            function enroll () {
                enrollmentOperation = ts.enroll(user);
                enrollmentOperation.start(enrollmentObserver);
            }

            function cancel () {
                if (enrollmentOperation !== null)
                    enrollmentOperation.cancel();
            }

            function remove() {
                clearanceOperation = ts.clear(user);
                clearanceOperation.start(clearanceObserver);
            }

            signal enrollmentProgressed(double progress, var hints)
            signal enrollmentCompleted()
            signal enrollmentFailed(int error)

            Component.onCompleted: {
                sizeOperation = ts.size(user);
                sizeOperation.start(sizeObserver);
            }

            Component.onDestruction: {
                if (enrollmentOperation !== null)
                    enrollmentOperation.cancel();

                if (sizeOperation !== null)
                    sizeOperation.cancel();

                if (clearanceOperation !== null)
                    clearanceOperation.cancel();
            }
        }

        Component {
            id: fingerprintPage
            Fingerprint {
                onRequestPasscode: p.passcodeSet = !p.passcodeSet
                onRequestFingerprintsRemoval: p.remove()
            }
        }
    }
}
