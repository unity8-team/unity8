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

#ifndef PREFERENCE_H
#define PREFERENCE_H

#include <QSettings>
#include <QStandardPaths>
#include <QObject>
#include <QDebug>
#include <QList>
#include <QColor>

class Preferences: public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString accountName READ accountName WRITE setAccountName NOTIFY accountNameChanged)
    Q_PROPERTY(bool haveLocalUser READ haveLocalUser WRITE setHaveLocalUser NOTIFY haveLocalUserChanged)
    Q_PROPERTY(bool firstLocalLogin READ firstLocalLogin WRITE setFirstLocalLogin NOTIFY firstLocalLoginChanged)

public:
    Preferences(QObject *parent = 0);
    QString accountName() const;
    void setAccountName(const QString &accountName);

    bool haveLocalUser() const;
    void setHaveLocalUser(bool haveLocalUser);

    bool firstLocalLogin() const;
    void setFirstLocalLogin(bool firstLocalLogin);

    Q_INVOKABLE QString colorForNotebook(const QString &notebookGuid);

signals:
    void accountNameChanged();
    void haveLocalUserChanged();
    void firstLocalLoginChanged();

private:
    QSettings m_settings;
    QList<QString> m_notebookColors;
};

#endif
