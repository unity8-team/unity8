#include "fetchnotesjob.h"

#include "notesstore.h"

#include <QDebug>

FetchNotesJob::FetchNotesJob(evernote::edam::NoteStoreClient *client,
                             const QString &token,
                             const QString &filterNotebookGuid, QObject *parent) :
    QThread(parent),
    m_client(client),
    m_token(token),
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
        m_client->findNotesMetadata(results, m_token.toStdString(), filter, start, end, resultSpec);
    } catch(evernote::edam::EDAMUserException) {
        errorCode = NotesStore::ErrorCodeUserException;
    } catch(evernote::edam::EDAMSystemException) {
        errorCode = NotesStore::ErrorCodeSystemException;
    } catch(evernote::edam::EDAMNotFoundException) {
        errorCode = NotesStore::ErrorCodeNotFoundExcpetion;
    }
    emit resultReady(errorCode, results);
}
