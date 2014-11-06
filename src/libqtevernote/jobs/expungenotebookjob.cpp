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

#include "expungenotebookjob.h"

#include <QDebug>

ExpungeNotebookJob::ExpungeNotebookJob(const QString &guid, QObject *parent) :
    NotesStoreJob(parent),
    m_guid(guid)
{
}

bool ExpungeNotebookJob::operator==(const EvernoteJob *other) const
{
    const ExpungeNotebookJob *otherJob = qobject_cast<const ExpungeNotebookJob*>(other);
    if (!otherJob) {
        return false;
    }
    return this->m_guid == otherJob->m_guid;
}

void ExpungeNotebookJob::attachToDuplicate(const EvernoteJob *other)
{
    const ExpungeNotebookJob *otherJob = static_cast<const ExpungeNotebookJob*>(other);
    connect(otherJob, &ExpungeNotebookJob::jobDone, this, &ExpungeNotebookJob::jobDone);
}

void ExpungeNotebookJob::startJob()
{
    client()->expungeNotebook(token().toStdString(), m_guid.toStdString());
}

void ExpungeNotebookJob::emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage)
{
    emit jobDone(errorCode, errorMessage, m_guid);
}
