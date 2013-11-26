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

#include "fetchnotesjob.h"

#include "notesstore.h"

#include <QDebug>

FetchNotesJob::FetchNotesJob( const QString &filterNotebookGuid, QObject *parent) :
    EvernoteJob(parent),
    m_filterNotebookGuid(filterNotebookGuid)
{
}

void FetchNotesJob::run()
{
    // TODO: fix start/end (use smaller chunks and continue fetching if there are more notes available)
    int32_t start = 0;
    int32_t end = 10000;

    // Prepare filter
    evernote::edam::NoteFilter filter;
    filter.notebookGuid = m_filterNotebookGuid.toStdString();
    filter.__isset.notebookGuid = !m_filterNotebookGuid.isEmpty();

    // Prepare ResultSpec
    evernote::edam::NotesMetadataResultSpec resultSpec;
    resultSpec.includeNotebookGuid = true;
    resultSpec.__isset.includeNotebookGuid = true;
    resultSpec.includeTitle = true;
    resultSpec.__isset.includeTitle = true;

    NotesStore::ErrorCode errorCode = NotesStore::ErrorCodeNoError;
    evernote::edam::NotesMetadataList results;

    try {
        client()->findNotesMetadata(results, token().toStdString(), filter, start, end, resultSpec);
    } catch(evernote::edam::EDAMUserException) {
        errorCode = NotesStore::ErrorCodeUserException;
    } catch(evernote::edam::EDAMSystemException) {
        errorCode = NotesStore::ErrorCodeSystemException;
    } catch(evernote::edam::EDAMNotFoundException) {
        errorCode = NotesStore::ErrorCodeNotFoundExcpetion;
    }
    emit resultReady(errorCode, results);
}
