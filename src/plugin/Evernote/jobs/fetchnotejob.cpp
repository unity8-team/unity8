#include "fetchnotejob.h"

FetchNoteJob::FetchNoteJob(const QString &guid, QObject *parent) :
    EvernoteJob(parent),
    m_guid(guid)
{
}

void FetchNoteJob::run()
{
    NotesStore::ErrorCode errorCode = NotesStore::ErrorCodeNoError;
    evernote::edam::Note result;
    try {
        client()->getNote(result, token().toStdString(), m_guid.toStdString(), true, true, false, false);
    } catch (evernote::edam::EDAMUserException) {
        errorCode = NotesStore::ErrorCodeUserException;
    } catch (evernote::edam::EDAMSystemException) {
        errorCode = NotesStore::ErrorCodeSystemException;
    } catch (evernote::edam::EDAMNotFoundException) {
        errorCode = NotesStore::ErrorCodeNotFoundExcpetion;
    } catch (...) {
        catchTransportException();
        errorCode = NotesStore::ErrorCodeConnectionLost;
    }

    emit resultReady(errorCode, result);
}
