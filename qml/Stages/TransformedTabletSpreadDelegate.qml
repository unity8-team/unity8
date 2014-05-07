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
    property real animatedProgress: 0
    property bool selected: false
    property bool otherSelected: false

    property real startDistance: units.gu(5)
    property real endDistance: units.gu(.5)

    property real startScale: 1.1
    property real endScale: 0.7
    property real dragStartScale: startScale + .4

    property real startAngle: 15
    property real endAngle: 5

    onSelectedChanged: {
        if (selected) {
            priv.snapshot();
        }
        priv.isSelected = selected;
    }

    onOtherSelectedChanged: {
        if (otherSelected) {
            priv.snapshot();
        }
        priv.otherSelected = otherSelected;
    }

    Connections {
        target: spreadView

        onPhaseChanged: {
            if (spreadView.phase == 1) {
                var endValue = -spreadView.width + (root.zIndex * root.endDistance);
                var startValue = endValue + spreadView.width;
                var startProgress = (spreadView.phase0Width + spreadView.phase1Width - zIndex * spreadView.tileDistance) / spreadView.width;
                priv.phase2StartTranslate = priv.easingAnimation(0, 1, startValue, endValue, startProgress);
                print("calculating end value for", root.zIndex, priv.phase2StartTranslate, "startprogress:", startProgress)

                priv.phase2StartScale = priv.easingAnimation(0, 1, root.startScale, root.endScale, startProgress)
                priv.phase2StartAngle = priv.easingAnimation(0, 1, root.startAngle, root.endAngle, startProgress)
            }
        }
    }

    QtObject {
        id: priv

        property bool nextInStack: spreadView.nextInStack == index;
        property real animatedEndDistance: linearAnimation(0, 2, root.endDistance, 0, root.progress)

        property real phase2StartTranslate
        property real phase2StartScale
        property real phase2StartAngle

        property bool isSelected: false
        property bool otherSelected: false
        property real selectedProgress
        property real selectedXTranslate
        property real selectedAngle
        property real selectedScale
        property real selectedOpacity

        function snapshot() {
            selectedProgress = root.progress;
            selectedXTranslate = xTranslate;
            selectedAngle = angle;
            selectedScale = scale;
            selectedOpacity = opacity;
//            selectedTopMarginProgress = topMarginProgress;
        }

        // This calculates how much negative progress there can be if unwinding the spread completely
        // the progress for each tile starts at 0 when it crosses the right edge, so the later a tile comes in,
        // the bigger its negativeProgress can be.
        property real negativeProgress: {
//            if (index == 1 && spreadView.phase < 2) {
//                return 0;
//            }
            return -root.zIndex * spreadView.tileDistance / spreadView.width;
        }

        function linearAnimation(startProgress, endProgress, startValue, endValue, progress) {
            // progress : progressDiff = value : valueDiff => value = progress * valueDiff / progressDiff
            return (progress - startProgress) * (endValue - startValue) / (endProgress - startProgress) + startValue;
        }

        function easingAnimation(startProgress, endProgress, startValue, endValue, progress) {
            helperEasingCurve.progress = progress - startProgress;
            helperEasingCurve.period = endProgress - startProgress;
            return helperEasingCurve.value * (endValue - startValue) + startValue;
        }

        property real xTranslate: {
            var newTranslate = 0;

            if (otherSelected) {
                return priv.selectedXTranslate
            }

            if (isSelected) {
                print("progress:", root.progress)
                if (model.stage == ApplicationInfoInterface.MainStage) {
                    return linearAnimation(selectedProgress, negativeProgress, selectedXTranslate, -spreadView.width, root.progress)
                } else {
                    return linearAnimation(selectedProgress, negativeProgress, selectedXTranslate, -spreadView.sideStageWidth, root.progress)
                }
            }

            if (active) {
                newTranslate -= root.width
            }
            if (nextInStack && spreadView.phase == 0) {
                if (model.stage == ApplicationInfoInterface.MainStage) {
                    if (spreadView.sideStageVisible) {
                        // Move it so it appears from behind the side stage immediately
                        newTranslate += -spreadView.sideStageWidth;
                    }
                    newTranslate += linearAnimation(0, 1, 0, -spreadView.sideStageWidth, root.animatedProgress)
                } else {
                    newTranslate += linearAnimation(0, 1, 0, -spreadView.sideStageWidth, root.animatedProgress)
                }
            }

            if (spreadView.phase == 1) {
                if (nextInStack) {
                    if (model.stage == ApplicationInfoInterface.MainStage) {
                        var startValue = -spreadView.sideStageWidth + (spreadView.sideStageVisible ? -spreadView.sideStageWidth : 0)
//                        var endValue = -spreadView.width + spreadView.width * root.zIndex / 6;
                        newTranslate += linearAnimation(0, 1, startValue, priv.phase2StartTranslate, root.animatedProgress);
                    } else {
                        var endValue = -spreadView.width + spreadView.width * root.zIndex / 6;
                        newTranslate += linearAnimation(0, 1, -spreadView.sideStageWidth, priv.phase2StartTranslate, root.animatedProgress);
                    }
                } else if (root.active) {
                    var endValue = -spreadView.width + spreadView.width * root.zIndex / 6;
                    newTranslate = linearAnimation(0, 1, -root.width, priv.phase2StartTranslate, root.progress);
                } else {
                    var endValue = -spreadView.width + spreadView.width * root.zIndex / 6;
                    newTranslate += linearAnimation(0, 1, 0, priv.phase2StartTranslate, root.progress);
                }
            }

            if (spreadView.phase == 2) {
                newTranslate = -easingCurve.value * spreadView.width + (root.zIndex * animatedEndDistance);
            }

            return newTranslate;
        }

        property real scale: {
            if (otherSelected) {
                return selectedScale;
            }

            if (selected) {
                return linearAnimation(selectedProgress, negativeProgress, selectedScale, 1, root.progress)
            }

            if (spreadView.phase == 0) {
                if (nextInStack) {
                    return linearAnimation(0, 1, root.dragStartScale, 1, root.animatedProgress);
                } else if (active) {
                    return 1;
                } else {
                    return linearAnimation(0, 2, root.startScale, root.endScale, root.progress)
                }
            }

            if (spreadView.phase == 1) {
                if (active || nextInStack) {
                    return linearAnimation(0, 1, 1, priv.phase2StartScale, root.progress)
                }
                return linearAnimation(0, 1, root.startScale, priv.phase2StartScale, root.progress)
            }

            if (spreadView.phase == 2) {
                return root.startScale - easingCurve.value * (root.startScale - root.endScale)
            }

            return 1;
        }

        property real angle: {
            if (otherSelected) {
                return selectedAngle;
            }
            if (selected) {
                return linearAnimation(selectedProgress, negativeProgress, selectedAngle, 0, root.progress)
            }

            if (spreadView.phase == 0) {
                if (nextInStack) {
                    return linearAnimation(0, 1, root.startAngle, 0, root.animatedProgress)
                }
            }
            if (spreadView.phase == 1) {
                if (nextInStack) {
                    return linearAnimation(0, 1, root.startAngle, priv.phase2StartAngle, root.animatedProgress)
                }

                return linearAnimation(0, 1, 0, priv.phase2StartAngle, root.progress)
            }
            if (spreadView.phase == 2) {
                return root.startAngle - easingCurve.value * (root.startAngle - root.endAngle);
            }

            return 0;
        }

        property real opacity: {
            if (otherSelected) {
//                if (active && root.progress == 0) {
//                    fadeBackInAnimation.start()
//                }
                return linearAnimation(selectedProgress, negativeProgress, selectedOpacity, 0, root.progress)
            }

            return 1;
        }
    }

    transform: [
        Rotation {
            origin { x: 0; y: spreadView.height / 2 }
            axis { x: 0; y: 1; z: 0 }
            angle: priv.angle
        },
        Scale {
            origin { x: 0; y: spreadView.height / 2 }
            xScale: priv.scale
            yScale: xScale
        },
        Translate {
            x: priv.xTranslate
        }
    ]
    opacity: priv.opacity

    UbuntuNumberAnimation {
        id: fadeBackInAnimation
        target: root
        property: "opacity"
        duration: UbuntuAnimation.SlowDuration
        from: 0
        to: 1
    }

    EasingCurve {
        id: easingCurve
        type: EasingCurve.OutSine
        period: 1
        progress: root.progress
    }

    EasingCurve {
        id: helperEasingCurve
        type: easingCurve.type
        period: easingCurve.period
    }
}
