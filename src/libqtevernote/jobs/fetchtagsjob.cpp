/*
 * Copyright: 2014 Canonical, Ltd
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

#include "fetchtagsjob.h"

FetchTagsJob::FetchTagsJob(QObject *parent) :
    NotesStoreJob(parent)
{
}

bool FetchTagsJob::operator==(const EvernoteJob *other) const
{
    const FetchTagsJob  *otherJob = qobject_cast<const FetchTagsJob*>(other);
    if (!otherJob) {
        return false;
    }
    return true;
}

void FetchTagsJob::attachToDuplicate(const EvernoteJob *other)
{
    const FetchTagsJob *otherJob = static_cast<const FetchTagsJob*>(other);
    connect(otherJob, &FetchTagsJob::jobDone, this, &FetchTagsJob::jobDone);
}

void FetchTagsJob::startJob()
{
    client()->listTags(m_results, token().toStdString());
}

void FetchTagsJob::emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage)
{
    emit jobDone(errorCode, errorMessage, m_results);
}
