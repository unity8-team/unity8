/*
 * Copyright: 2013 Canonical, Ltd
 *
 * This file is part of reminders
 *
 * reminders is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
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
 */

#ifndef USERSTORE_H
#define USERSTORE_H

#include "evernoteconnection.h"

//Evernote SDK
#include "UserStore.h"

#include <QObject>

class UserStore : public QObject
{
    Q_OBJECT

    // TODO: Once we need more than just the username, turn this into a class User
    Q_PROPERTY(QString username READ username NOTIFY usernameChanged)

public:
    static UserStore* instance();

    QString username() const;

signals:
    void usernameChanged(const QString &username);

private slots:
    void fetchUsername();

    void fetchUsernameJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &result);

private:
    static UserStore* s_instance;
    explicit UserStore(QObject *parent = 0);

    QString m_username;
};

#endif // USERSTORE_H
