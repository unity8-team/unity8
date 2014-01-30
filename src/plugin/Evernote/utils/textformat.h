/*
 * Copyright: 2013 Canonical, Ltd
 *
 * This file is part of reminders-app
 *
 * reminders-app is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
 */

#ifndef TEXTFORMAT_H
#define TEXTFORMAT_H

#include <QObject>

class TextFormat: public QObject
{
    Q_OBJECT
    Q_ENUMS(Format)
public:
    enum Format {
        Bold,
        Italic,
        Underlined
    };
    Q_DECLARE_FLAGS(Formats, Format)

    TextFormat(QObject *parent = 0);
};
Q_DECLARE_OPERATORS_FOR_FLAGS(TextFormat::Formats)
Q_DECLARE_METATYPE(TextFormat::Format)

#endif
