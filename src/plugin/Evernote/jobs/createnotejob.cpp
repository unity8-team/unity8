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

CreateNoteJob::CreateNoteJob(const QString &title, const QString &notebookGuid, const QString &content, QObject *parent) :
    NotesStoreJob(parent),
    m_title(title),
    m_notebookGuid(notebookGuid),
    m_content(content)
{
}

void CreateNoteJob::startJob()
{
    evernote::edam::Note input;
    input.title = m_title.toStdString();
    input.__isset.title = true;
    if (!m_notebookGuid.isEmpty()) {
        input.notebookGuid = m_notebookGuid.toStdString();
        input.__isset.notebookGuid = true;
    }
    if (!m_content.isEmpty()) {
        input.content = m_content.toStdString();
        input.__isset.content = true;
        input.contentLength = m_content.length();
        input.__isset.contentLength = true;
    }

    client()->createNote(m_resultNote, token().toStdString(), input);
}

void CreateNoteJob::emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage)
{
    emit jobDone(errorCode, errorMessage, m_resultNote);
}
