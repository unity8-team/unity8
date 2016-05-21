/*
 * Copyright (C) 2016 Canonical, Ltd.
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
 *
 * Authored by Jonas G. Drange <jonas.drange@canonical.com>
 */

#ifndef UBUNTUSETTINGSFINGERPRINT_H
#define UBUNTUSETTINGSFINGERPRINT_H

#include <QObject>
#include <QSvgRenderer>

class UbuntuSettingsFingerprint : public QObject
{
    Q_OBJECT
public:
    explicit UbuntuSettingsFingerprint(QObject* parent = nullptr);

    Q_PROPERTY(qlonglong uid READ uid CONSTANT)
    qlonglong uid() const;
};

#endif // UBUNTUSETTINGSFINGERPRINT_H
