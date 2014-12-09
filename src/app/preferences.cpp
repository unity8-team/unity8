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
#include "preferences.h"

Preferences::Preferences(QObject *parent): QObject(parent),
    m_settings(QStandardPaths::standardLocations(QStandardPaths::ConfigLocation).first() + "/com.ubuntu.reminders/reminders.conf", QSettings::IniFormat)
{
    m_notebookColors.append("#35af44");
    m_notebookColors.append("#298bd6");
    m_notebookColors.append("#d33781");
    m_notebookColors.append("#b68b01");
    m_notebookColors.append("#db3131");
    m_notebookColors.append("#2ba098");
}

QString Preferences::accountName() const
{
    return m_settings.value("accountName").toString();
}

void Preferences::setAccountName(const QString &accountName)
{
    m_settings.setValue("accountName", accountName);
    emit accountNameChanged();
}

bool Preferences::haveLocalUser() const
{
    return m_settings.value("haveLocalUser", false).toBool();
}

void Preferences::setHaveLocalUser(bool haveLocalUser)
{
    m_settings.setValue("haveLocalUser", true);
    emit haveLocalUserChanged();
}

QString Preferences::colorForNotebook(const QString &notebookGuid)
{
    m_settings.beginGroup("notebookColors");
    QString colorName = m_settings.value(notebookGuid).toString();

    if (colorName.isEmpty()) {
        QHash<QString, int> usedColors;
        foreach (const QString &tmp, m_settings.allKeys()) {
            usedColors[m_settings.value(tmp).toString()]++;
        }

        while (colorName.isEmpty()) {
            foreach (const QString &c, m_notebookColors) {
                if (usedColors[c] == 0) {
                    colorName = c;
                    break;
                }
                usedColors[c]--;
            }
        }

        m_settings.setValue(notebookGuid, colorName);
    }
    m_settings.endGroup();
    return colorName;
}
