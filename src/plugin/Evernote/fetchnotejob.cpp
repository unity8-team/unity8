#include "fetchnotejob.h"

FetchNoteJob::FetchNoteJob(evernote::edam::NoteStoreClient *client, const QString &token, const QString &guid, QObject *parent) :
    QThread(parent),
    m_client(client),
    m_token(token),
    m_guid(guid)
{
}

void FetchNoteJob::run()
{
    NotesStore::ErrorCode errorCode = NotesStore::ErrorCodeNoError;
    evernote::edam::Note result;
    try {
        m_client->getNote(result, m_token.toStdString(), m_guid.toStdString(), true, true, false, false);
    } catch(evernote::edam::EDAMUserException) {
        errorCode = NotesStore::ErrorCodeUserException;
    } catch(evernote::edam::EDAMSystemException) {
        errorCode = NotesStore::ErrorCodeSystemException;
    } catch(evernote::edam::EDAMNotFoundException) {
        errorCode = NotesStore::ErrorCodeNotFoundExcpetion;
    }

    emit resultReady(errorCode, result);
}
