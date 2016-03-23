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

ListView {
    id: monthView

    property bool collapsed: false
    property var currentDate: selectedDate.midMonth()
    property var firstDayOfWeek: Qt.locale(i18n.language).firstDayOfWeek
    property var maximumDate
    property var minimumDate
    property var selectedDate: priv.today

    Component.onCompleted: {
        priv.__populateModel()
        timer.start()
    }

    onCurrentIndexChanged: {
        if (!priv.ready) return

        console.log("INDEX CHANGE", currentIndex)
        currentDate = currentItem.midMonth.midMonth()
    }

    onCurrentDateChanged: {
        if (!priv.ready) return

        priv.__populateModel();
    }

    onMaximumDateChanged: {
        if (!priv.ready) return

        priv.__populateModel()
    }

    onMinimumDateChanged: {
        if (!priv.ready) return

        priv.__populateModel()
    }

    ListModel {
        id: calendarModel
    }

    QtObject {
        id: priv

        property bool ready: false
        property int squareUnit: monthView.width / 7
        property int verticalMargin: units.gu(1)
        property var today: (new Date()).midnight()

        function __withinLowerMonthBound(date) {
            return minimumDate == undefined || date.midMonth() >= minimumDate.midMonth()
        }

        function __withinUpperMonthBound(date) {
            return maximumDate == undefined || date.midMonth() <= maximumDate.midMonth()
        }

        function __getRealMinimumDate(date) {
            if (minimumDate != undefined && minimumDate > date) {
                return minimumDate;
            }
            return date;
        }

        function __getRealMaximumDate(date) {
            if (maximumDate != undefined && maximumDate < date) {
                return maximumDate;
            }
            return date;
        }

        function __populateModel() {
            //  disable the onCurrentIndexChanged logic
            priv.ready = false

            console.log("REPOPULATE MODEL")

            var minimumAddedDate = priv.__getRealMinimumDate(currentDate.addMonths(-2)).midMonth();
            var maximumAddedDate = priv.__getRealMaximumDate(currentDate.addMonths(2)).midMonth();

            // Remove old minimum months
            while (calendarModel.count > 0 && calendarModel.get(0).midMonth.midMonth() < minimumAddedDate) {
                calendarModel.remove(0);
            }
            // Remove old maximum months
            while (calendarModel.count > 0 && calendarModel.get(calendarModel.count - 1).midMonth.midMonth() > maximumAddedDate) {
                calendarModel.remove(calendarModel.count - 1);
            }

            // Add new months
            var i = 0;
            while (calendarModel.count > 0 && calendarModel.get(0).midMonth.midMonth() > minimumAddedDate) {
                calendarModel.insert(0, { "midMonth": calendarModel.get(0).midMonth.midMonth().addMonths(-1) });
                ++i;
            }

            if (calendarModel.count > 0) {
                i = 0;
                while (calendarModel.count > 0 && calendarModel.get(calendarModel.count - 1).midMonth.midMonth() < maximumAddedDate) {
                    calendarModel.append({ "midMonth": calendarModel.get(calendarModel.count - 1).midMonth.midMonth().addMonths(1) });
                    ++i;
                }
            } else {
                i = 0;
                do {
                    calendarModel.append({ "midMonth": minimumAddedDate.addMonths(i) });
                    ++i;
                } while (calendarModel.get(i-1).midMonth.midMonth() < maximumAddedDate)
            }

            currentIndex = DateExt.diffMonths(minimumAddedDate, currentDate);

            // Ok, we're all set up. enable the onCurrentIndexChanged logic
            priv.ready = true

            console.log("REPOPED")
        }
    }

    Timer {
        id: timer
        interval: 60000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: priv.today = (new Date()).midnight()
    }

    width: parent.width
    height: priv.squareUnit * (collapsed ? 1 : 6) + priv.verticalMargin * 2
    interactive: !collapsed
    clip: true
    cacheBuffer: 2000000000//Math.max((width+1) * 2, 0)
    highlightRangeMode: ListView.StrictlyEnforceRange
    preferredHighlightBegin: 0
    preferredHighlightEnd: width
    model: calendarModel
    orientation: ListView.Horizontal
    snapMode: ListView.SnapOneItem
    focus: true

    Keys.onLeftPressed: selectedDate.addDays(-1)
    Keys.onRightPressed: selectedDate.addDays(1)

    delegate: Item {
        id: monthItem

        ListView.onAdd: console.log("ITEM ADDED!", monthStart.getMonth())
        ListView.onRemove: console.log("ITEM REMOVE!", monthStart.getMonth())

        property int currentWeekRow: Math.floor((selectedDate.getTime() - gridStart.getTime()) / Date.msPerWeek)
        property var gridStart: monthStart.weekStart(firstDayOfWeek)
        property var monthEnd: monthStart.addMonths(1)
        property var monthStart: model.midMonth.monthStart()
        property var midMonth: model.midMonth

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

                    property bool isCurrent: (dayStart.getFullYear() == selectedDate.getFullYear() &&
                                              dayStart.getMonth() == selectedDate.getMonth() &&
                                              dayStart.getDate() == selectedDate.getDate())
                    property bool isCurrentMonth: monthStart <= dayStart && dayStart < monthEnd
                    property bool isCurrentWeek: row == currentWeekRow
                    property bool isSunday: weekday == 0
                    property bool isToday: dayStart.getTime() == priv.today.getTime()
                    property bool isWithinBounds: (minimumDate == undefined || dayStart >= minimumDate) &&
                                                  (maximumDate == undefined || dayStart <= maximumDate)
                    property int row: Math.floor(index / 7)
                    property int weekday: (index % 7 + firstDayOfWeek) % 7
                    property real bottomMargin: (row == 5 || (collapsed && isCurrentWeek)) ? -priv.verticalMargin : 0
                    property real topMargin: (row == 0 || (collapsed && isCurrentWeek)) ? -priv.verticalMargin : 0
                    property var dayStart: gridStart.addDays(index)

                    // Styling properties
                    property color color: theme.palette.normal.backgroundText
                    property color todayColor: theme.palette.normal.positive
                    property var backgroundColor: "transparent" // FIXME use color instead var when Qt will fix the bug with the binding (loses alpha)
                    property var sundayBackgroundColor: "#19AEA79F" // FIXME use color instead var when Qt will fix the bug with the binding (loses alpha)

                    visible: collapsed ? isCurrentWeek : true
                    width: priv.squareUnit
                    height: priv.squareUnit

//                    ItemStyle.class: "day"
                    Item {
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
                            font.pixelSize: units.dp(isCurrent ? 36 : 20)
                            color: isToday ? dayItem.todayColor : dayItem.color
                            opacity: isWithinBounds ? isCurrentMonth ? 1. : 0.3 : 0.1

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

                        onReleased: {
                            if (isWithinBounds) monthView.selectedDate = dayStart
                        }
                    }
                }
            }
        }
    }
}
