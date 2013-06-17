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

ListView {
    id: monthView

    property bool compressed: false
    property var currentDate: selectedDate.monthStart().addDays(15)
    property var firstDayOfWeek: Qt.locale(i18n.language).firstDayOfWeek
    property var maximumDate: (new Date()).monthStart().addMonths(2)
    property var minimumDate: (new Date()).monthStart().addMonths(-2)
    property var selectedDate: intern.today

    ItemStyle.class: "calendar"

    onCurrentItemChanged: if (currentDate != currentItem.monthStart) currentDate = currentItem.monthStart.addDays(15)
    onCurrentDateChanged: if (currentIndex != __diffMonths(minimumDate, currentDate)) currentIndex = __diffMonths(minimumDate, currentDate)

    onSelectedDateChanged: {
        if (selectedDate < minimumDate || selectedDate > maximumDate)
            return

        var monthEnd = currentItem != null ? currentItem.monthEnd : (new Date()).monthStart().addMonths(1)
        var monthStart = currentItem != null ? currentItem.monthStart : (new Date()).monthStart()

        currentIndex = __diffMonths(minimumDate, selectedDate)
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
        objectName: "intern"

        property int squareUnit: monthView.width / 7
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
    height: intern.squareUnit * (compressed ? 1 : 6) + intern.verticalMargin * 2
    interactive: !compressed
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
        property var monthStart: minimumDate.monthStart().addMonths(index)

        width: monthView.width
        height: monthView.height

        Grid {
            id: monthGrid

            rows: 6
            columns: 7
            y: intern.verticalMargin
            width: intern.squareUnit * columns
            height: intern.squareUnit * rows

            Repeater {
                model: monthGrid.rows * monthGrid.columns
                delegate: Item {
                    id: dayItem
                    objectName: "dayItem" + index

                    property bool isCurrent: (dayStart.getFullYear() == selectedDate.getFullYear() &&
                                              dayStart.getMonth() == selectedDate.getMonth() &&
                                              dayStart.getDate() == selectedDate.getDate())
                    property bool isCurrentMonth: monthStart <= dayStart && dayStart < monthEnd
                    property bool isCurrentWeek: row == currentWeekRow
                    property bool isSunday: weekday == 0
                    property bool isToday: dayStart.getTime() == intern.today.getTime()
                    property bool isWithinBounds: dayStart >= minimumDate && dayStart <= maximumDate
                    property int row: Math.floor(index / 7)
                    property int weekday: (index % 7 + firstDayOfWeek) % 7
                    property real bottomMargin: (row == 5 || (compressed && isCurrentWeek)) ? -intern.verticalMargin : 0
                    property real topMargin: (row == 0 || (compressed && isCurrentWeek)) ? -intern.verticalMargin : 0
                    property var dayStart: gridStart.addDays(index)

                    // Styling properties
                    property color color: "#757373"
                    property color todayColor: "#DD4814"
                    property string fontSize: "large"
                    property var backgroundColor: "transparent" // FIXME use color instead var when Qt will fix the bug with the binding (loses alpha)
                    property var sundayBackgroundColor: "#19AEA79F" // FIXME use color instead var when Qt will fix the bug with the binding (loses alpha)

                    visible: compressed ? isCurrentWeek : true
                    width: intern.squareUnit
                    height: intern.squareUnit

                    ItemStyle.class: "day"
                    ItemStyle.delegate: Item {
                        anchors {
                            fill: parent
                            topMargin: dayItem.topMargin
                            bottomMargin: dayItem.bottomMargin
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: color.a > 0
                            color: isSunday ? dayItem.sundayBackgroundColor : dayItem.backgroundColor
                        }

                        Label {
                            anchors.centerIn: parent
                            text: dayStart.getDate()
                            fontSize: dayItem.fontSize
                            color: isToday ? dayItem.todayColor : dayItem.color
                            scale: isCurrent ? 1.8 : 1.
                            opacity: isWithinBounds ? isCurrentMonth ? 1. : 0.3 : 0.1

                            Behavior on scale {
                                NumberAnimation { duration: 50 }
                            }
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
}
