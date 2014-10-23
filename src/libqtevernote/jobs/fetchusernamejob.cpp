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

#include "fetchusernamejob.h"

FetchUsernameJob::FetchUsernameJob(QObject *parent) :
    UserStoreJob(parent)
{
}

bool FetchUsernameJob::operator==(const EvernoteJob *other) const
{
    const FetchUsernameJob *otherJob = qobject_cast<const FetchUsernameJob*>(other);
    if (!otherJob) {
        return false;
    }
    return true;
}

void FetchUsernameJob::attachToDuplicate(const EvernoteJob *other)
{
    const FetchUsernameJob *otherJob = static_cast<const FetchUsernameJob*>(other);
    connect(otherJob, &FetchUsernameJob::jobDone, this, &FetchUsernameJob::jobDone);
}

void FetchUsernameJob::startJob()
{
    evernote::edam::User user;
    client()->getUser(user, token().toStdString());
    m_result = QString::fromStdString(user.username);
}

void FetchUsernameJob::emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage)
{
    emit jobDone(errorCode, errorMessage, m_result);
}
