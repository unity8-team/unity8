#include "fetchnotebooksjob.h"

#include <QDebug>

FetchNotebooksJob::FetchNotebooksJob(evernote::edam::NoteStoreClient *client, const QString &token, QObject *parent) :
    QThread(parent),
    m_client(client),
    m_token(token)
{
}


void FetchNotebooksJob::run()
{
    NotesStore::ErrorCode errorCode = NotesStore::ErrorCodeNoError;
    std::vector<evernote::edam::Notebook> results;
    try {
        m_client->listNotebooks(results, m_token.toStdString());
    } catch(evernote::edam::EDAMUserException) {
        errorCode = NotesStore::ErrorCodeUserException;
    } catch(evernote::edam::EDAMSystemException) {
        errorCode = NotesStore::ErrorCodeSystemException;
    }
    emit resultReady(errorCode, results);
}
