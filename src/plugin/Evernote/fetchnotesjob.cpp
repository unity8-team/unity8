#include "fetchnotesjob.h"

#include "notesstore.h"

#include <QDebug>

FetchNotesJob::FetchNotesJob(evernote::edam::NotesMetadataList *results,
                             evernote::edam::NoteStoreClient *client,
                             const QString &token,
                             const QString &filterNotebookGuid, QObject *parent) :
    QThread(parent),
    m_results(results),
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

    try {
        m_client->findNotesMetadata(*m_results, m_token.toStdString(), filter, start, end, resultSpec);
    } catch(...) {
        qDebug() << "error fetching notes";
        return;
    }
    emit resultReady();
}
