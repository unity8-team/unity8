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

#include "savenotejob.h"
#include "note.h"

#include <QDebug>

SaveNoteJob::SaveNoteJob(Note *note, QObject *parent) :
    NotesStoreJob(parent)
{
    // Need to clone it. As startJob() will run in another thread we can't access the real note from there.
    m_note = note->clone();

    // Make sure we delete the clone when done
    m_note->setParent(this);
}

bool SaveNoteJob::operator==(const EvernoteJob *other) const
{
    const SaveNoteJob *otherJob = qobject_cast<const SaveNoteJob*>(other);
    if (!otherJob) {
        return false;
    }
    return this->m_note == otherJob->m_note;
}

void SaveNoteJob::attachToDuplicate(const EvernoteJob *other)
{
    const SaveNoteJob *otherJob = static_cast<const SaveNoteJob*>(other);
    connect(otherJob, &SaveNoteJob::jobDone, this, &SaveNoteJob::jobDone);
}

void SaveNoteJob::startJob()
{
    evernote::edam::Note note;

    note.guid = m_note->guid().toStdString();
    note.__isset.guid = true;

    note.title = m_note->title().toStdString();
    note.__isset.title = true;

    note.notebookGuid = m_note->notebookGuid().toStdString();
    note.__isset.notebookGuid = true;

    note.updated = m_note->updated().toMSecsSinceEpoch();
    note.__isset.updated = true;

    std::vector<evernote::edam::Guid> tags;
    foreach (const QString &tag, m_note->tagGuids()) {
        tags.push_back(tag.toStdString());
    }
    note.tagGuids = tags;
    note.__isset.tagGuids = true;

    note.content = m_note->enmlContent().toStdString();
    note.__isset.content = true;
    note.contentLength = m_note->enmlContent().length();

    note.__isset.attributes = true;
    note.attributes.reminderOrder = m_note->reminderOrder();
    note.attributes.__isset.reminderOrder = true;
    note.attributes.reminderTime = m_note->reminderTime().toMSecsSinceEpoch();
    note.attributes.__isset.reminderTime = true;
    note.attributes.reminderDoneTime = m_note->reminderDoneTime().toMSecsSinceEpoch();
    note.attributes.__isset.reminderDoneTime = true;

    note.resources.clear();
    foreach (Resource *resource, m_note->resources()) {
        evernote::edam::Resource evResource;
        evResource.noteGuid = m_note->guid().toStdString();
        evResource.__isset.noteGuid = true;
        evResource.mime = resource->type().toStdString();
        evResource.__isset.mime = true;

        evResource.data.bodyHash = resource->hash().toStdString();
        evResource.data.__isset.bodyHash = true;

        QByteArray data = resource->data();
        evResource.data.body.assign(data.data(), data.length());
        evResource.data.__isset.body = true;

        evResource.data.size = data.length();
        evResource.data.__isset.size = true;
        evResource.__isset.data = true;

        evResource.attributes.fileName = resource->fileName().toStdString();
        evResource.attributes.__isset.fileName = true;
        evResource.__isset.attributes = true;

        note.resources.push_back(evResource);
    }
    note.__isset.resources = true;

    client()->updateNote(m_resultNote, token().toStdString(), note);
}

void SaveNoteJob::emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage)
{
    emit jobDone(errorCode, errorMessage, m_resultNote);
}
