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
#include <unistd.h>
#include <sys/types.h>
#include <QProcessEnvironment>

#include "ubuntusettingsfingerprint.h"

UbuntuSettingsFingerprint::UbuntuSettingsFingerprint(QObject* parent)
    : QObject(parent)
{
}

qlonglong UbuntuSettingsFingerprint::uid() const
{
    return qlonglong(getuid());
}

bool UbuntuSettingsFingerprint::debug() const
{
    return QProcessEnvironment::systemEnvironment().contains(
        QLatin1String("USC_FINGERPRINT_DEBUG")
    );
}
