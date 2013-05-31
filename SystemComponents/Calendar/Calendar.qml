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

// TODO clamp selectedDate and currentDate with maximumDate and minimumDate
// TODO remove gotoNextMonth
// TODO rewrite the logic

ListView {
    id: monthView

    readonly property var monthEnd: currentItem != null ? currentItem.monthEnd : (new Date()).monthStart().addMonths(1)
    readonly property var monthStart: currentItem != null ? currentItem.monthStart : (new Date()).monthStart()

    property var minimumDate: (new Date()).monthStart().addMonths(-2)
    property var maximumDate: (new Date()).monthStart().addMonths(2)
    property var currentDate: intern.today.monthStart()
    property alias selectedDate: intern.currentDayStart

    signal gotoNextMonth(int month)

    onGotoNextMonth: {
        if (monthStart.getMonth() != month) {
            var i = intern.monthIndex0, m = intern.today.getMonth()
            while (m != month) {
                m = (m + 1) % 12
                i = i + 1
            }
            currentIndex = i
        }
    }

    onCurrentItemChanged: {
        currentDate = currentItem.monthStart
    }

    onSelectedDateChanged: {
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

        // number of months in the calendar, represents the number of pages/items of the listview
        property int monthCount: __diffMonths(minimumDate, maximumDate) + 1

        property int squareUnit: monthView.width / 8
        property int verticalMargin: units.gu(1)

        // first day of the week // TODO export property
        property int weekstartDay: Qt.locale(i18n.language).firstDayOfWeek
        property var currentDayStart: today
        property var today: (new Date()).midnight() // TODO: update at midnight
    }

    width: parent.width
    height: intern.squareUnit * 6 + intern.verticalMargin * 2;
    interactive: true
    clip: true
    orientation: ListView.Horizontal
    snapMode: ListView.SnapOneItem
    cacheBuffer: width + 1
    highlightRangeMode: ListView.StrictlyEnforceRange
    preferredHighlightBegin: 0
    preferredHighlightEnd: width
    model: intern.monthCount
    focus: true

    Keys.onLeftPressed: selectedDate.addDays(-1)
    Keys.onRightPressed: selectedDate.addDays(1)

    Component.onCompleted: currentIndex = __diffMonths(minimumDate, selectedDate)

    delegate: Item {
        id: monthItem

        property int currentWeekRow: Math.floor((selectedDate.getTime() - gridStart.getTime()) / Date.msPerWeek)
        property var gridStart: monthStart.weekStart(intern.weekstartDay)
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

                    property bool isCurrent: dayStart.getTime() == intern.currentDayStart.getTime()
                    property bool isCurrentMonth: monthStart <= dayStart && dayStart < monthEnd
                    property bool isCurrentWeek: row == currentWeekRow
                    property bool isSunday: weekday == 0
                    property bool isToday: dayStart.getTime() == intern.today.getTime()
                    property int row: Math.floor(index / 7)
                    property int weekday: (index % 7 + intern.weekstartDay) % 7
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
                        opacity: isCurrentMonth ? 1. : 0.3

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
                        onReleased: monthView.selectedDate = dayStart
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
