/*
 * Copyright: 2013 Canonical, Ltd
 *
 * This file is part of reminders-app
 *
 * reminders-app is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders-app is distributed in the hope that it will be useful,
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
    NotesStoreJob(parent),
    m_guid(note->guid()),
    m_title(note->title()),
    m_notebookGuid(note->notebookGuid()),
    m_content(note->content())
{
}

void SaveNoteJob::startJob()
{
    evernote::edam::Note note;
    note.guid = m_guid.toStdString();
    note.__isset.guid = true;
    note.title = m_title.toStdString();
    note.__isset.title = true;
    note.notebookGuid = m_notebookGuid.toStdString();
    note.__isset.notebookGuid = true;
    note.content = m_content.toStdString();
    note.__isset.content = true;
    note.contentLength = m_content.length();

    client()->updateNote(m_note, token().toStdString(), note);
}

void SaveNoteJob::emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage)
{
    emit jobDone(errorCode, errorMessage, m_note);
}
