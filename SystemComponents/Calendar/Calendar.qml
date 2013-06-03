/*
 * Copyright 2013 Canonical Ltd.
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
 */

import QtQuick 2.0
import Ubuntu.Components 0.1
import "dateExt.js" as DateExt
import "colorUtils.js" as Color

ListView {
    id: monthView

    property var firstDayOfWeek: Qt.locale(i18n.language).firstDayOfWeek
    property var currentDate: intern.today.monthStart()
    property var minimumDate: (new Date()).monthStart().addMonths(-2)
    property var maximumDate: (new Date()).monthStart().addMonths(2)
    property var selectedDate: intern.today

    onCurrentItemChanged: currentDate = currentItem.monthStart

    onSelectedDateChanged: {
        var monthEnd = currentItem != null ? currentItem.monthEnd : (new Date()).monthStart().addMonths(1)
        var monthStart = currentItem != null ? currentItem.monthStart : (new Date()).monthStart()

        if (selectedDate < monthStart) {
            if (currentIndex > 0) {
                currentIndex = currentIndex - 1
            }
        }
        else if (selectedDate >= monthEnd) {
            if (currentIndex < count - 1) {
                currentIndex = currentIndex + 1
            }
        }
    }

    function __diffMonths(dateA, dateB) {
        var months;
        months = (dateB.getFullYear() - dateA.getFullYear()) * 12;
        months -= dateA.getMonth();
        months += dateB.getMonth();
        return Math.max(months, 0);
    }

    QtObject {
        id: intern

        property int squareUnit: monthView.width / 8
        property int verticalMargin: units.gu(1)
        property var today: (new Date()).midnight()
    }

    Timer {
        id: timer
        interval: 60000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: intern.today = (new Date()).midnight()
    }

    width: parent.width
    height: intern.squareUnit * 6 + intern.verticalMargin * 2;
    interactive: true
    clip: true
    cacheBuffer: width + 1
    highlightRangeMode: ListView.StrictlyEnforceRange
    preferredHighlightBegin: 0
    preferredHighlightEnd: width
    model: __diffMonths(minimumDate, maximumDate) + 1
    orientation: ListView.Horizontal
    snapMode: ListView.SnapOneItem
    focus: true

    Keys.onLeftPressed: selectedDate.addDays(-1)
    Keys.onRightPressed: selectedDate.addDays(1)

    Component.onCompleted: {
        timer.start()
        currentIndex = __diffMonths(minimumDate, selectedDate)
    }

    delegate: Item {
        id: monthItem

        property int currentWeekRow: Math.floor((selectedDate.getTime() - gridStart.getTime()) / Date.msPerWeek)
        property var gridStart: monthStart.weekStart(firstDayOfWeek)
        property var monthEnd: monthStart.addMonths(1)
        property var monthStart: minimumDate.addMonths(index)

        width: monthView.width
        height: monthView.height

        Grid {
            id: monthGrid

            rows: 6
            columns: 7
            x: intern.squareUnit / 2
            y: intern.verticalMargin
            width: intern.squareUnit * columns
            height: intern.squareUnit * rows

            Repeater {
                model: monthGrid.rows * monthGrid.columns
                delegate: Item {
                    id: dayItem

                    property bool isCurrent: dayStart.getTime() == selectedDate.getTime()
                    property bool isCurrentMonth: monthStart <= dayStart && dayStart < monthEnd
                    property bool isCurrentWeek: row == currentWeekRow
                    property bool isSunday: weekday == 0
                    property bool isToday: dayStart.getTime() == intern.today.getTime()
                    property bool isWithinBounds: dayStart >= minimumDate && dayStart <= maximumDate
                    property int row: Math.floor(index / 7)
                    property int weekday: (index % 7 + firstDayOfWeek) % 7
                    property real bottomMargin: row == 5 ? -intern.verticalMargin : 0
                    property real topMargin: row == 0 ? -intern.verticalMargin : 0
                    property var dayStart: gridStart.addDays(index)

                    visible: true
                    width: intern.squareUnit
                    height: intern.squareUnit

                    Rectangle {
                        anchors {
                            fill: parent
                            topMargin: dayItem.topMargin
                            bottomMargin: dayItem.bottomMargin
                        }
                        visible: isSunday
                        color: Color.warmGrey
                        opacity: 0.1
                    }

                    Text {
                        anchors.centerIn: parent
                        text: dayStart.getDate()
                        font: themeDummy.font
                        color: isToday ? Color.ubuntuOrange : themeDummy.color
                        scale: isCurrent ? 1.8 : 1.
                        opacity: isWithinBounds ? isCurrentMonth ? 1. : 0.3 : 0.1

                        Behavior on scale {
                            NumberAnimation { duration: 50 }
                        }
                    }

                    MouseArea {
                        anchors {
                            fill: parent
                            topMargin: dayItem.topMargin
                            bottomMargin: dayItem.bottomMargin
                        }

                        onReleased: if (isWithinBounds) monthView.selectedDate = dayStart
                    }
                }
            }
        }
    }

    Label {
        visible: false
        id: themeDummy
        fontSize: "large"
    }
}
