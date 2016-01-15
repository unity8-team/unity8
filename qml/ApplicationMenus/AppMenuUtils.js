/*
 * Copyright 2015 Canonical Ltd.
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

.pragma library

String.prototype.htmlLabelFromMenuLabel = function (underline) {
    var replacements = [
        {
            char: "_",
            searchExpr: /_/g,
            doubleReplacement: "_"
        }, {
           char: "&",
           searchExpr: /&(?!amp;)/g,
           doubleReplacement: "&amp;"
        }
    ];
    var text = this;

    var i = 0;
    for (; i < replacements.length; i++) {
        text = parseShortcutChararacter(text, underline, replacements[i]);
    }
    return text;
}

function parseShortcutChararacter(text, underline, replacement) {
    text = text.replace(new RegExp(replacement.char + replacement.char, "g"), replacement.doubleReplacement);

    if (!underline) {
        return text.replace(replacement.searchExpr, "");
    }

    var original = text;
    var output = "";
    var current = 0
    var next = text.search(replacement.searchExpr);
    if (next === -1) return text;

    while (next !== -1) {
        output += text.slice(current, next);
        current = next+1;

        var rest = text.slice(current);
        text = "<u>" + rest[0] + "</u>" + rest.slice(1);
        next = text.search(replacement.searchExpr);
    }
    output += text;
    return output;
}

String.prototype.actionKeyFromMenuLabel = function () {
    var replacements = [
        {
            char: "_",
            searchExpr: /_/g,
            doubleReplacement: "_"
        }, {
           char: "&",
           searchExpr: /&(?!amp;)/g,
           doubleReplacement: "&amp;"
        }
    ];
    var text = this;

    var i = 0;
    var replaced = false;
    for (; i < replacements.length; i++) {
        var actionKey = parseActionKeyChararacter(text, replacements[i]);
        if (actionKey !== "") return actionKey;
    }
    return "";
}

function parseActionKeyChararacter(original, replacement) {
    var text = original.replace(new RegExp(replacement.char + replacement.char, "g"), replacement.doubleReplacement);

    var output = "";
    var iter = 0;
    var next = text.search(replacement.searchExpr);
    if (next === -1) return "";

    while (next !== -1) {
        var char = text.slice(next+1, next+2);
        if (char === "") break;

        if (iter > 0) output += "+";
        output += char;

        text = text.slice(next+2);
        next = text.search(replacement.searchExpr)
    }
    return output;
}
