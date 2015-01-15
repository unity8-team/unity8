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

#include "createnotejob.h"

#include <QDebug>

CreateNoteJob::CreateNoteJob(Note *note, QObject *parent) :
    NotesStoreJob(parent)
{
    m_note = note->clone();
    m_note->setParent(this);
}

bool CreateNoteJob::operator==(const EvernoteJob *other) const
{
    const CreateNoteJob *otherJob = qobject_cast<const CreateNoteJob*>(other);
    if (!otherJob) {
        return false;
    }
    return this->m_note->guid() == otherJob->m_note->guid();
}

void CreateNoteJob::attachToDuplicate(const EvernoteJob *other)
{
    const CreateNoteJob *otherJob = static_cast<const CreateNoteJob*>(other);
    connect(otherJob, &CreateNoteJob::jobDone, this, &CreateNoteJob::jobDone);
}

void CreateNoteJob::startJob()
{
    qDebug() << "creating note:" << m_note->guid() << m_note->enmlContent() << m_note->notebookGuid() << m_note->title();
    evernote::edam::Note input;
    input.updateSequenceNum = m_note->updateSequenceNumber();
    input.__isset.updateSequenceNum = true;

    input.title = m_note->title().toStdString();
    input.__isset.title = true;
    if (!m_note->notebookGuid().isEmpty()) {
        input.notebookGuid = m_note->notebookGuid().toStdString();
        input.__isset.notebookGuid = true;
    }
    if (!m_note->enmlContent().isEmpty()) {
        input.content = m_note->enmlContent().toStdString();
        input.__isset.content = true;
        input.contentLength = m_note->enmlContent().length();
        input.__isset.contentLength = true;
    }
    input.created = m_note->created().toMSecsSinceEpoch();
    input.__isset.created = true;
    input.updated = m_note->updated().toMSecsSinceEpoch();
    input.__isset.updated = true;

    std::vector<evernote::edam::Guid> tags;
    foreach (const QString &tag, m_note->tagGuids()) {
        tags.push_back(tag.toStdString());
    }
    input.tagGuids = tags;
    input.__isset.tagGuids = true;

    client()->createNote(m_resultNote, token().toStdString(), input);
}

void CreateNoteJob::emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage)
{
    emit jobDone(errorCode, errorMessage, m_note->guid(), m_resultNote);
}
