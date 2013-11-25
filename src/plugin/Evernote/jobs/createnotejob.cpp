#include "createnotejob.h"

#include <QDebug>

CreateNoteJob::CreateNoteJob(Note *note, QObject *parent) :
    EvernoteJob(parent),
    m_note(note)
{
}

void CreateNoteJob::run()
{
    NotesStore::ErrorCode errorCode = NotesStore::ErrorCodeNoError;

    try {
        evernote::edam::Note input;
        input.title = m_note->title().toStdString();
        input.__isset.title = true;
        input.notebookGuid = m_note->notebookGuid().toStdString();
        input.__isset.notebookGuid = true;
        input.content = m_note->content().toStdString();
        input.__isset.content = true;
        input.contentLength = m_note->content().length();
        input.__isset.contentLength = true;

        evernote::edam::Note result;
        client()->createNote(result, token().toStdString(), input);

        m_note->setGuid(QString::fromStdString(result.guid));

    } catch(evernote::edam::EDAMUserException e) {
        errorCode = NotesStore::ErrorCodeUserException;
    } catch(evernote::edam::EDAMSystemException) {
        errorCode = NotesStore::ErrorCodeSystemException;
    }
    emit resultReady(errorCode, m_note);
}
