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

#include "fetchnotesjob.h"

#include "notesstore.h"

// evernote sdk
#include "Limits_constants.h"

FetchNotesJob::FetchNotesJob(const QString &filterNotebookGuid, const QString &searchWords, int startIndex, int chunkSize, QObject *parent) :
    NotesStoreJob(parent),
    m_filterNotebookGuid(filterNotebookGuid),
    m_searchWords(searchWords),
    m_startIndex(startIndex),
    m_chunkSize(chunkSize)
{
}

bool FetchNotesJob::operator==(const EvernoteJob *other) const
{
    const FetchNotesJob *otherJob = qobject_cast<const FetchNotesJob*>(other);
    if (!otherJob) {
        return false;
    }
    return this->m_filterNotebookGuid == otherJob->m_filterNotebookGuid
            && this->m_searchWords == otherJob->m_searchWords;
}

void FetchNotesJob::attachToDuplicate(const EvernoteJob *other)
{
    const FetchNotesJob *otherJob = static_cast<const FetchNotesJob*>(other);
    connect(otherJob, &FetchNotesJob::jobDone, this, &FetchNotesJob::jobDone);
}

QString FetchNotesJob::toString() const
{
    return QString("%1, NotebookFilter: %2, SearchWords: %3, StartIndex: %4, ChunkSize: %5")
            .arg(metaObject()->className())
            .arg(m_filterNotebookGuid)
            .arg(m_searchWords)
            .arg(m_startIndex)
            .arg(m_chunkSize);
}

void FetchNotesJob::startJob()
{
    int32_t start = m_startIndex;
    int32_t max = m_chunkSize;

    // Prepare filter
    evernote::edam::NoteFilter filter;
    filter.notebookGuid = m_filterNotebookGuid.toStdString();
    filter.__isset.notebookGuid = !m_filterNotebookGuid.isEmpty();

    filter.words = m_searchWords.toStdString();
    filter.__isset.words = !m_searchWords.isEmpty();

    // Prepare ResultSpec
    evernote::edam::NotesMetadataResultSpec resultSpec;

    resultSpec.includeNotebookGuid = true;
    resultSpec.__isset.includeNotebookGuid = true;

    resultSpec.includeCreated = true;
    resultSpec.__isset.includeCreated = true;

    resultSpec.includeUpdated = true;
    resultSpec.__isset.includeUpdated = true;

    resultSpec.includeTitle = true;
    resultSpec.__isset.includeTitle = true;

    resultSpec.includeAttributes = true;
    resultSpec.__isset.includeAttributes = true;

    resultSpec.includeTagGuids = true;
    resultSpec.__isset.includeTagGuids = true;

    resultSpec.includeUpdateSequenceNum = true;
    resultSpec.__isset.includeUpdateSequenceNum = true;

    client()->findNotesMetadata(m_results, token().toStdString(), filter, start, max, resultSpec);
}

void FetchNotesJob::emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage)
{
    emit jobDone(errorCode, errorMessage, m_results, m_filterNotebookGuid);
}
