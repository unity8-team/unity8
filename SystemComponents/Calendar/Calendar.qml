import QtQuick 2.0
import Ubuntu.Components 0.1
import "dateExt.js" as DateExt
import "colorUtils.js" as Color

ListView {
    id: monthView

    readonly property var monthStart: currentItem != null ? currentItem.monthStart : (new Date()).monthStart()
    readonly property var monthEnd: currentItem != null ? currentItem.monthEnd : (new Date()).monthStart().addMonths(1)
    readonly property var currentDayStart: intern.currentDayStart

    property bool compressed: false
    readonly property real compressedHeight: {
        var height =  intern.squareUnit + intern.verticalMargin * 2 ;
//        if( pageStack.header ) {
//            height += pageStack.header.height;
//        }
        return height;
    }

    readonly property real expandedHeight: {
        var height = intern.squareUnit * 6 + intern.verticalMargin * 2;
//        if( pageStack.header ) {
//            height += pageStack.header.height;
//        }
        return height;
    }

    signal incrementCurrentDay
    signal decrementCurrentDay

    signal gotoNextMonth(int month)
    signal focusOnDay(var dayStart)

    onCurrentItemChanged: {
        if (currentItem == null) {
            intern.currentDayStart = intern.currentDayStart
            return
        }
        if (currentItem.monthStart <= intern.currentDayStart && intern.currentDayStart < currentItem.monthEnd)
            return
        if (currentItem.monthStart <= intern.today && intern.today < currentItem.monthEnd)
            intern.currentDayStart = intern.today
        else
            intern.currentDayStart = currentItem.monthStart
    }

    onIncrementCurrentDay: {
        var t = intern.currentDayStart.addDays(1)
        if (t < monthEnd) {
            intern.currentDayStart = t
        }
        else if (currentIndex < count - 1) {
            intern.currentDayStart = t
            currentIndex = currentIndex + 1
        }
    }

    onDecrementCurrentDay: {
        var t = intern.currentDayStart.addDays(-1)
        if (t >= monthStart) {
            intern.currentDayStart = t
        }
        else if (currentIndex > 0) {
            intern.currentDayStart = t
            currentIndex = currentIndex - 1
        }
    }

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

    onFocusOnDay: {
        if (dayStart < monthStart) {
            if (currentIndex > 0) {
                intern.currentDayStart = dayStart
                currentIndex = currentIndex - 1
            }
        }
        else if (dayStart >= monthEnd) {
            if (currentIndex < count - 1) {
                intern.currentDayStart = dayStart
                currentIndex = currentIndex + 1
            }
        }
        else intern.currentDayStart = dayStart
    }

    focus: true
    Keys.onLeftPressed: decrementCurrentDay()
    Keys.onRightPressed: incrementCurrentDay()

    QtObject {
        id: intern

        property int squareUnit: monthView.width / 8
        property int verticalMargin: units.gu(1)
        property int weekstartDay: Qt.locale(i18n.language).firstDayOfWeek
        property int monthCount: 49 // months for +-2 years

        property var today: (new Date()).midnight() // TODO: update at midnight
        property var currentDayStart: today
        property int monthIndex0: Math.floor(monthCount / 2)
        property var monthStart0: today.monthStart()
    }

    width: parent.width
    height: compressed ? compressedHeight : expandedHeight

    interactive: !compressed
    clip: true
    orientation: ListView.Horizontal
    snapMode: ListView.SnapOneItem
    cacheBuffer: width + 1

    highlightRangeMode: ListView.StrictlyEnforceRange
    preferredHighlightBegin: 0
    preferredHighlightEnd: width

    model: intern.monthCount
    currentIndex: intern.monthIndex0

    delegate: Item {
        id: monthItem

        property var monthStart: intern.monthStart0.addMonths(index - intern.monthIndex0)
        property var monthEnd: monthStart.addMonths(1)
        property var gridStart: monthStart.weekStart(intern.weekstartDay)
        property int currentWeekRow: Math.floor((currentDayStart.getTime() - gridStart.getTime()) / Date.msPerWeek)

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
                    property var dayStart: gridStart.addDays(index)
                    property bool isCurrentMonth: monthStart <= dayStart && dayStart < monthEnd
                    property bool isToday: dayStart.getTime() == intern.today.getTime()
                    property bool isCurrent: dayStart.getTime() == intern.currentDayStart.getTime()
                    property int weekday: (index % 7 + intern.weekstartDay) % 7
                    property bool isSunday: weekday == 0
                    property int row: Math.floor(index / 7)
                    property bool isCurrentWeek: row == currentWeekRow
                    property real topMargin: (row == 0 || (monthView.compressed && isCurrentWeek)) ? -intern.verticalMargin : 0
                    property real bottomMargin: (row == 5 || (monthView.compressed && isCurrentWeek)) ? -intern.verticalMargin : 0
                    visible: monthView.compressed ? isCurrentWeek : true
                    width: intern.squareUnit
                    height: intern.squareUnit
                    Rectangle {
                        visible: isSunday
                        anchors.fill: parent
                        anchors.topMargin: dayItem.topMargin
                        anchors.bottomMargin: dayItem.bottomMargin
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
                        anchors.fill: parent
                        anchors.topMargin: dayItem.topMargin
                        anchors.bottomMargin: dayItem.bottomMargin
                        onReleased: monthView.focusOnDay(dayStart)
                    }
                    // Component.onCompleted: console.log(dayStart, intern.currentDayStart)
                }
            }
        }

        // Component.onCompleted: console.log("Created delegate for month", index, monthStart, gridStart, currentWeekRow, currentWeekRowReal)
    }

    Label {
        visible: false
        id: themeDummy
        fontSize: "large"
        // Component.onCompleted: console.log(color, Qt.lighter(color, 1.74))
    }
}
