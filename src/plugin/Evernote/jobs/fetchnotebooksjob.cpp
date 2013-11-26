#include "fetchnotebooksjob.h"

#include <QDebug>

FetchNotebooksJob::FetchNotebooksJob(QObject *parent) :
    EvernoteJob(parent)
{
}


void FetchNotebooksJob::run()
{
    NotesStore::ErrorCode errorCode = NotesStore::ErrorCodeNoError;
    std::vector<evernote::edam::Notebook> results;
    try {
        client()->listNotebooks(results, token().toStdString());
    } catch(evernote::edam::EDAMUserException) {
        errorCode = NotesStore::ErrorCodeUserException;
    } catch(evernote::edam::EDAMSystemException) {
        errorCode = NotesStore::ErrorCodeSystemException;
    }
    emit resultReady(errorCode, results);
}
