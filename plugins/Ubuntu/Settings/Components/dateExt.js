.pragma library

function diffMonths(dateA, dateB) {
    var months;
    months = (dateB.getFullYear() - dateA.getFullYear()) * 12;
    months -= dateA.getMonth();
    months += dateB.getMonth();
    return Math.max(months, 0);
}

Date.msPerDay = 86400e3
Date.msPerWeek = Date.msPerDay * 7

Date.leapYear = function(year) {
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
}

Date.daysInMonth = function(year, month) {
    return [
        31/*Jan*/, 28/*Feb*/, 31/*Mar*/, 30/*Apr*/, 31/*May*/, 30/*Jun*/,
        31/*Jul*/, 31/*Aug*/, 30/*Sep*/, 31/*Oct*/, 30/*Nov*/, 31/*Dec*/
    ][month] + (month == 1) * Date.leapYear(year)
}

Date.prototype.midnight = function() {
    var date = new Date(this)
    date.setHours(0,0,0,0);
    return date
}

Date.prototype.addDays = function(days) {
    var date = new Date(this)
    date.setTime(date.getTime() + Date.msPerDay * days)
    return date
}

Date.prototype.addMonths = function(months) {
    var date = new Date(this)
    date.setMonth(date.getMonth() + months)
    return date
}
