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

import QtQuick 2.4
import Ubuntu.Components 1.3
import "dateExt.js" as DateExt
import "Calendar.js" as Cal

ListView {
    id: monthView

    property bool collapsed: false
    property var currentDate: new Date(priv.today.year, priv.today.month, 1)
    property var firstDayOfWeek: Qt.locale(i18n.language).firstDayOfWeek
    property var maximumDate
    property var minimumDate
    property var selectedDate: new Date(priv.today.year, priv.today.month, priv.today.day)

    function reset() {
        if (!priv.ready) return;
        currentDate = new Date(priv.today.year, priv.today.month, 1)
    }

    Component.onCompleted: {
        priv.__populateModel();
    }

    onCurrentIndexChanged: {
        if (!priv.ready) return;

        currentDate = new Date(currentItem.month.year, currentItem.month.month, 1);
    }

    ListModel {
        id: calendarModel
    }

    QtObject {
        id: priv

        property bool ready: false
        property int squareUnit: monthView.width / 7
        property int verticalMargin: units.gu(1)
        property var today: new Cal.Day().fromDate((new Date()))

        property var currentMonth: new Cal.Month().fromDate(currentDate)
        property var selectedDay: new Cal.Day().fromDate(selectedDate)
        property var minimumMonth: minimumDate ? new Cal.Month().fromDate(minimumDate) : undefined
        property var maximumMonth: maximumDate ? new Cal.Month().fromDate(maximumDate) : undefined

        property var minimumDay: minimumDate ? new Cal.Day().fromDate(minimumDate) : undefined
        property var maximumDay: maximumDate ? new Cal.Day().fromDate(maximumDate) : undefined

        onCurrentMonthChanged: {
            if (!ready) return
            __populateModel();
        }
        onSelectedDayChanged: {
            if (!ready) return
            __populateModel();
        }
        onMinimumMonthChanged: {
            if (!ready) return
            __populateModel();
        }
        onMaximumMonthChanged: {
            if (!ready) return
            __populateModel();
        }

        function __getRealMinimumMonth(month) {
            if (minimumMonth !== undefined && minimumMonth > month) {
                return minimumMonth;
            }
            return month;
        }

        function __getRealMaximumMonth(date) {
            if (maximumMonth !== undefined && maximumMonth < month) {
                return maximumMonth;
            }
            return month;
        }

        function __populateModel() {
            //  disable the onCurrentIndexChanged logic
            priv.ready = false;

            var minimumMonth = __getRealMinimumMonth(currentMonth).addMonths(-2);
            var maximumMonth = __getRealMinimumMonth(currentMonth).addMonths(2);

            // Remove old minimum months
            while (calendarModel.count > 0 && new Cal.Month(calendarModel.get(0).month) < minimumMonth) {
                calendarModel.remove(0);
            }
            // Remove old maximum months
            while (calendarModel.count > 0 && new Cal.Month(calendarModel.get(calendarModel.count - 1).month) > maximumMonth) {
                calendarModel.remove(calendarModel.count - 1);
            }

            if (calendarModel.count > 0) {
                // Add new months
                var firstMonth = new Cal.Month(calendarModel.get(0).month);
                while (firstMonth > minimumMonth) {
                    calendarModel.insert(0, { "month": firstMonth.addMonths(-1) });
                    firstMonth = new Cal.Month(calendarModel.get(0).month);
                }

                var lastMonth = new Cal.Month(calendarModel.get(calendarModel.count - 1).month);
                while (lastMonth < maximumMonth) {
                    calendarModel.append({ "month": lastMonth.addMonths(1) });
                    lastMonth = new Cal.Month(calendarModel.get(calendarModel.count - 1).month);
                }
            } else {
                var i = 0;
                do {
                    calendarModel.append({ "month": minimumMonth.addMonths(i) });
                    ++i;
                } while (minimumMonth.addMonths(i) <= maximumMonth)
            }

            currentIndex = currentMonth - minimumMonth;

            // Ok, we're all set up. enable the onCurrentIndexChanged logic
            priv.ready = true
        }
    }

    LiveTimer {
        frequency: LiveTimer.Minute
        onTrigger: {
            var today = new Cal.Day().fromDate((new Date()));
            if (!priv.today.equals(today)) {
                priv.today = today;
                reset();
            }
        }
    }

    width: parent.width
    height: priv.squareUnit * (collapsed ? 1 : 6) + priv.verticalMargin * 2
    interactive: !collapsed
    clip: true
    cacheBuffer: Math.max((width+1) * 3, 0) // one page left, one page right
    highlightRangeMode: ListView.StrictlyEnforceRange
    preferredHighlightBegin: 0
    preferredHighlightEnd: width
    model: calendarModel
    orientation: ListView.Horizontal
    snapMode: ListView.SnapOneItem
    focus: true
    highlightFollowsCurrentItem: true

    Keys.onLeftPressed: selectedDate.addDays(-1)
    Keys.onRightPressed: selectedDate.addDays(1)

    delegate: Item {
        id: monthItem

        property int currentWeekRow: Math.floor((priv.selectedDay - gridStart) / 7)
        property var gridStart: monthStart.weekStart(firstDayOfWeek)
        property var monthEnd: monthStart.addMonths(1)
        property var monthStart: new Cal.Day(model.month.year, model.month.month, 1)

        property var month: new Cal.Month(model.month)

        width: monthView.width
        height: monthView.height

        Grid {
            id: monthGrid

            rows: 6
            columns: 7
            y: priv.verticalMargin
            width: priv.squareUnit * columns
            height: priv.squareUnit * rows

            Repeater {
                model: monthGrid.rows * monthGrid.columns
                delegate: Item {
                    id: dayItem
                    objectName: "dayItem" + index

                    property bool isCurrent: dayStart.equals(priv.selectedDay)
                    property bool isCurrentMonth: (monthStart < dayStart || monthStart.equals(dayStart))  && dayStart < monthEnd
                    property bool isCurrentWeek: row == currentWeekRow
                    property bool isSunday: weekday == 0
                    property bool isToday: dayStart.equals(priv.today)
                    property bool isWithinBounds: (priv.minimumDay === undefined || dayStart >= priv.minimumDay) &&
                                                  (priv.maximumDay === undefined || dayStart <= priv.maximumDay)
                    property int row: Math.floor(index / 7)
                    property int weekday: (index % 7 + firstDayOfWeek) % 7
                    property real bottomMargin: (row == 5 || (collapsed && isCurrentWeek)) ? -priv.verticalMargin : 0
                    property real topMargin: (row == 0 || (collapsed && isCurrentWeek)) ? -priv.verticalMargin : 0
                    property var dayStart: gridStart.addDays(index)

                    visible: collapsed ? isCurrentWeek : true
                    width: priv.squareUnit
                    height: priv.squareUnit

                    Item {
                        anchors {
                            fill: parent
                            topMargin: dayItem.topMargin
                            bottomMargin: dayItem.bottomMargin
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: isSunday
                            opacity: 0.1
                            color: UbuntuColors.warmGrey
                        }

                        Label {
                            anchors.centerIn: parent
                            text: dayStart.day
                            font.pixelSize: units.dp(isCurrent ? 36 : 20)
                            color: isCurrentMonth && isWithinBounds ? isToday ? UbuntuColors.green :
                                                                                theme.palette.normal.backgroundText :
                                                                      theme.palette.disabled.backgroundText
                            opacity: isWithinBounds ? 1. : 0.33

                            Behavior on font.pixelSize {
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

                        onClicked: {
                            if (isWithinBounds) monthView.selectedDate = new Date(dayStart.year, dayStart.month, dayStart.day)
                        }
                    }
                }
            }
        }
    }
}
