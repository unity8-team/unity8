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

#include "createtagjob.h"
#include "tag.h"

#include <QDebug>

CreateTagJob::CreateTagJob(Tag *tag, QObject *parent) :
    NotesStoreJob(parent),
    m_tag(tag->clone())
{
    m_tag->setParent(this);
    m_tag->setUpdateSequenceNumber(m_tag->updateSequenceNumber()+1);
}

void CreateTagJob::startJob()
{
    m_result.name = m_tag->name().toStdString();
    m_result.__isset.name = true;
    client()->createTag(m_result, token().toStdString(), m_result);
}

bool CreateTagJob::operator==(const EvernoteJob *other) const
{
    const CreateTagJob *otherJob = qobject_cast<const CreateTagJob*>(other);
    if (!otherJob) {
        return false;
    }
    return this->m_tag == otherJob->m_tag;
}

void CreateTagJob::attachToDuplicate(const EvernoteJob *other)
{
    const CreateTagJob *otherJob = static_cast<const CreateTagJob*>(other);
    connect(otherJob, &CreateTagJob::jobDone, this, &CreateTagJob::jobDone);
}

void CreateTagJob::emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage)
{
    emit jobDone(errorCode, errorMessage, m_tag->guid(), m_result);
}
