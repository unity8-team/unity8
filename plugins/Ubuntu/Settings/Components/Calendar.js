.pragma library
.import "dateExt.js" as DateExt

function Month(arg1, arg2) {
    if (arg1 === undefined) {
        var date = new Date();
        this.year = date.getFullYear();
        this.month = date.getMonth();
    }
    else if (arg1 !== undefined && arg2 === undefined) {
        this.year = arg1.year;
        this.month = arg1.month;
    } else {
        this.year = arg1;
        this.month = arg2;
    }
}

Month.prototype.fromDate = function(date) {
    return new Month(date.getFullYear(), date.getMonth());
}

Month.prototype.addMonths = function(months) {
    var date = new Date(this.year, this.month, 1).addMonths(months);
    return new Month(date.getFullYear(), date.getMonth());
}

Month.prototype.toString = function() {
    return JSON.stringify(this);
}

Month.prototype.valueOf = function() {
    return this.year * 12 + this.month;
}

function Day(arg1, arg2, arg3) {
    if (arg1 === undefined) {
        var date = new Date();
        this.year = date.getFullYear();
        this.month = date.getMonth();
        this.day = date.getDate();
    }
    else if (arg1 !== undefined && arg2 === undefined) {
        this.year = arg1.year;
        this.month = arg1.month;
        this.day = arg1.day;
    } else {
        this.year = arg1;
        this.month = arg2;
        this.day = arg3;
    }
}

Day.prototype.fromDate = function(date) {
    return new Day(date.getFullYear(), date.getMonth(), date.getDate());
}

Day.prototype.addMonths = function(months) {
    var date = new Date(this.year, this.month, this.day).addMonths(months);
    return new Day(date.getFullYear(), date.getMonth(), date.getDate());
}

Day.prototype.addDays = function(days) {
    var date = new Date(this.year, this.month, this.day).addDays(days);
    return new Day(date.getFullYear(), date.getMonth(), date.getDate());
}

Day.prototype.dayofweek = function ()	/* 1 <= m <= 12,  y > 1752 (in the U.K.) */
{
    var t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4];
    var y = this.year;
    y = y - ((this.month+1) < 3 ? 1 : 0);
    return (y + y/4 - y/100 + y/400 + t[this.month] + this.day) % 7;
}

Day.prototype.weekStart = function(weekStartDay) {
    var day = (new Date(this.year, this.month, this.day)).getDay(), n = 0
    while (day != weekStartDay) {
        if (day == 0) day = 6
        else day = day - 1
        n = n + 1
    }
    return this.addDays(-n)
}

Day.prototype.valueOf = function() {
    // make sure there are no crossover values.
    return this.year * 373 + this.month * 31 + this.day;
}

Day.prototype.toString = function() {
    return JSON.stringify(this);
}

Day.prototype.equals = function(other) {
    if (other instanceof Day) {
        return other.valueOf() == this.valueOf();
    }
    return false;
}
