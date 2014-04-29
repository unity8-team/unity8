/*
 * Copyright 2014 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
*/

import QtQuick 2.0
import Utils 0.1
import Ubuntu.Components 0.1
import Unity.Application 0.1

SpreadDelegate {
    id: root

    property bool active: false
    property int zIndex
    property real progress: 0

    property real startDistance: units.gu(5)
    property real endDistance: units.gu(.5)

    QtObject {
        id: priv

        property bool nextInStack: spreadView.nextInStack == index;
        property real animatedEndDistance: linearAnimation(0, 2, root.endDistance, 0, root.progress)

        function linearAnimation(startProgress, endProgress, startValue, endValue, progress) {
            // progress : progressDiff = value : valueDiff => value = progress * valueDiff / progressDiff
            return (progress - startProgress) * (endValue - startValue) / (endProgress - startProgress) + startValue;
        }

//        function easingAnimation(startProgress, endProgress, startValue, endValue, progress) {
//            helperEasingCurve.progress = progress - startProgress;
//            helperEasingCurve.period = endProgress - startProgress;
//            return helperEasingCurve.value * (endValue - startValue) + startValue;
//        }

        property real xTranslate: {
            var newTranslate = 0;
            if (active) {
                newTranslate -= root.width
            }
            if (nextInStack && spreadView.phase == 0) {
                if (model.stage == ApplicationInfoInterface.MainStage) {
                    if (spreadView.sideStageVisible) {
                        // Move it so it appears from behind the side stage immediately
                        newTranslate += -spreadView.sideStageWidth;
                    }
                    newTranslate += linearAnimation(0, 1, 0, -spreadView.sideStageWidth, root.progress)
                } else {
                    newTranslate += linearAnimation(0, 1, 0, -spreadView.sideStageWidth, root.progress)
                }
            }

            if (spreadView.phase == 1) {
                if (nextInStack) {
                    if (model.stage == ApplicationInfoInterface.MainStage) {
                        var startValue = -spreadView.sideStageWidth + (spreadView.sideStageVisible ? -spreadView.sideStageWidth : 0)
                        var endValue = -spreadView.width + spreadView.width * root.zIndex / 6;
                        newTranslate += linearAnimation(0, 1, startValue, endValue, root.progress);
                    } else {
                        var endValue = -spreadView.width + spreadView.width * root.zIndex / 6;
                        newTranslate += linearAnimation(0, 1, -spreadView.sideStageWidth, endValue, root.progress);
                    }
                } else if (root.active) {
                    var endValue = -spreadView.width + spreadView.width * root.zIndex / 6;
                    newTranslate = linearAnimation(0, 1, -root.width, endValue, root.progress);
                } else {
                    var endValue = -spreadView.width + spreadView.width * root.zIndex / 6;
                    print("endValue for", root.zIndex, "is", endValue)
                    newTranslate += linearAnimation(0, 1, 0, endValue, root.progress);
                }
                if (root.zIndex > 2) print("there's more! at", newTranslate)
            }

            if (spreadView.phase == 2) {
                var endValue = -spreadView.width + spreadView.width * root.zIndex / 6;
                var startValue = endValue + spreadView.width;
                newTranslate = linearAnimation(0, 1, startValue, endValue, root.progress);

                newTranslate = -easingCurve.value * spreadView.width + (root.zIndex * animatedEndDistance);
                print("easing curve:", easingCurve.progress, easingCurve.value)
            }

            return newTranslate;
        }
    }

    transform: Translate {
        x: priv.xTranslate
    }

    EasingCurve {
        id: easingCurve
        type: EasingCurve.OutExpo
        period: .55
        progress: root.progress
    }

//    EasingCurve {
//        id: easingTest
//        type: EasingCurve.InQuint
//        period: .55
//        progress: root.progress
//    }
}
