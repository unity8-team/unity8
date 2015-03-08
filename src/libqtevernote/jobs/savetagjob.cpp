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

#include "savetagjob.h"
#include "tag.h"

SaveTagJob::SaveTagJob(Tag *tag, QObject *parent) :
    NotesStoreJob(parent)
{
    // Need to clone it. As startJob() will run in another thread we can't access the real notebook from there.
    m_tag = tag->clone();

    // Make sure we delete the clone when done
    m_tag->setParent(this);
}

bool SaveTagJob::operator==(const EvernoteJob *other) const
{
    const SaveTagJob *otherJob = qobject_cast<const SaveTagJob*>(other);
    if (!otherJob) {
        return false;
    }
    return this->m_tag == otherJob->m_tag;
}

void SaveTagJob::attachToDuplicate(const EvernoteJob *other)
{
    const SaveTagJob *otherJob = static_cast<const SaveTagJob*>(other);
    connect(otherJob, &SaveTagJob::jobDone, this, &SaveTagJob::jobDone);
}

void SaveTagJob::startJob()
{
    m_result.guid = m_tag->guid().toStdString();
    m_result.__isset.guid = true;
    m_result.name = m_tag->name().toStdString();
    m_result.__isset.name = true;
    m_result.updateSequenceNum = m_tag->updateSequenceNumber();
    m_result.__isset.updateSequenceNum = true;

    client()->updateTag(token().toStdString(), m_result);
}

void SaveTagJob::emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage)
{
    emit jobDone(errorCode, errorMessage, m_result);
}
