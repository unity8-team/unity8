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
    NotesStoreJob(parent)
{
    // Need to clone it. As startJob() will run in another thread we can't access the real note from there.
    m_note = note->clone();

    // Make sure we delete the clone when done
    m_note->setParent(this);
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

    client()->updateNote(m_resultNote, token().toStdString(), note);
}

void SaveNoteJob::emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage)
{
    emit jobDone(errorCode, errorMessage, m_resultNote);
}
