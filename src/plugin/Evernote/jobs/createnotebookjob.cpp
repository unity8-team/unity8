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

#include "createnotebookjob.h"

#include <QDebug>

CreateNotebookJob::CreateNotebookJob(const QString &name, QObject *parent) :
    NotesStoreJob(parent),
    m_name(name)
{
}

void CreateNotebookJob::startJob()
{
    m_result.name = m_name.toStdString();
    m_result.__isset.name = true;
    client()->createNotebook(m_result, token().toStdString(), m_result);
}

bool CreateNotebookJob::operator==(const EvernoteJob *other) const
{
    const CreateNotebookJob *otherJob = qobject_cast<const CreateNotebookJob*>(other);
    if (!otherJob) {
        return false;
    }
    return this->m_name == otherJob->m_name;
}

void CreateNotebookJob::attachToDuplicate(const EvernoteJob *other)
{
    const CreateNotebookJob *otherJob = static_cast<const CreateNotebookJob*>(other);
    connect(otherJob, &CreateNotebookJob::jobDone, this, &CreateNotebookJob::jobDone);
}

void CreateNotebookJob::emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage)
{
    emit jobDone(errorCode, errorMessage, m_result);
}
