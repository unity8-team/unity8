#include "deletenotejob.h"

DeleteNoteJob::DeleteNoteJob(const QString &guid, QObject *parent):
    EvernoteJob(parent),
    m_guid(guid)
{
}

void DeleteNoteJob::run()
{
    NotesStore::ErrorCode errorCode = NotesStore::ErrorCodeNoError;
    try {
        client()->deleteNote(token().toStdString(), m_guid.toStdString());
    } catch(...) {
        catchTransportException();
    }
    emit resultReady(errorCode, m_guid);
}
