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

#include "fetchnotejob.h"

FetchNoteJob::FetchNoteJob(const QString &guid, LoadWhat what, QObject *parent) :
    NotesStoreJob(parent),
    m_guid(guid),
    m_what(what)
{
    qRegisterMetaType<LoadWhat>("LoadWhat");
}

bool FetchNoteJob::operator==(const EvernoteJob *other) const
{
    const FetchNoteJob *otherJob = qobject_cast<const FetchNoteJob*>(other);
    if (!otherJob) {
        return false;
    }
    return this->m_guid == otherJob->m_guid && this->m_what == otherJob->m_what;
}

void FetchNoteJob::attachToDuplicate(const EvernoteJob *other)
{
    const FetchNoteJob *otherJob = static_cast<const FetchNoteJob*>(other);
    connect(otherJob, &FetchNoteJob::resultReady, this, &FetchNoteJob::resultReady);
}

QString FetchNoteJob::toString() const
{
    return QString("%1, NoteGuid: %2, What: %3")
            .arg(metaObject()->className())
            .arg(m_guid)
            .arg(m_what == LoadContent ? "Content" : "Resources");
}

void FetchNoteJob::startJob()
{
    // Just in case we error out, make sure the reply can be idenfied by note guid
    m_result.guid = m_guid.toStdString();
    client()->getNote(m_result, token().toStdString(), m_guid.toStdString(), m_what == LoadContent, m_what == LoadResources, false, false);
}

void FetchNoteJob::emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage)
{
    emit resultReady(errorCode, errorMessage, m_result, m_what);
}
