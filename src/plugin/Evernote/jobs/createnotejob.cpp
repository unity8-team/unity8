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

#include "createnotejob.h"

#include <QDebug>

CreateNoteJob::CreateNoteJob(Note *note, QObject *parent) :
    EvernoteJob(parent),
    m_note(note)
{
}

void CreateNoteJob::run()
{
    NotesStore::ErrorCode errorCode = NotesStore::ErrorCodeNoError;

    try {
        evernote::edam::Note input;
        input.title = m_note->title().toStdString();
        input.__isset.title = true;
        input.notebookGuid = m_note->notebookGuid().toStdString();
        input.__isset.notebookGuid = true;
        input.content = m_note->content().toStdString();
        input.__isset.content = true;
        input.contentLength = m_note->content().length();
        input.__isset.contentLength = true;

        evernote::edam::Note result;
        client()->createNote(result, token().toStdString(), input);

        m_note->setGuid(QString::fromStdString(result.guid));

    } catch(evernote::edam::EDAMUserException e) {
        errorCode = NotesStore::ErrorCodeUserException;
    } catch(evernote::edam::EDAMSystemException) {
        errorCode = NotesStore::ErrorCodeSystemException;
    }
    emit resultReady(errorCode, m_note);
}
