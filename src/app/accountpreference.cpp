/*
 * Copyright: 2014 Canonical, Ltd
 *
 * This file is part of reminders
 *
 * reminders is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * reminders is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
 *          Riccardo Padovani <rpadovani@ubuntu.com>
 */
#include "accountpreference.h"

AccountPreference::AccountPreference(QObject *parent): QObject(parent),
    m_settings(QStandardPaths::standardLocations(QStandardPaths::ConfigLocation).first() + "/com.ubuntu.reminders/reminders.conf", QSettings::IniFormat)
{

}

QString AccountPreference::accountName() const
{
    return m_settings.value("accountName").toString();
}

void AccountPreference::setAccountName(const QString &accountName)
{
    m_settings.setValue("accountName", accountName);
    emit accountNameChanged();
}
