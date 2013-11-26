#include "savenotejob.h"
#include "note.h"

#include <QDebug>

SaveNoteJob::SaveNoteJob(Note *note, QObject *parent) :
    EvernoteJob(parent),
    m_note(note)
{
}

void SaveNoteJob::run()
{
    NotesStore::ErrorCode errorCode = NotesStore::ErrorCodeNoError;
    try {
        evernote::edam::Note note;
        note.guid = m_note->guid().toStdString();
        note.__isset.guid = true;
        note.title = m_note->title().toStdString();
        note.__isset.title = true;
        note.notebookGuid = m_note->notebookGuid().toStdString();
        note.__isset.notebookGuid = true;
        note.content = m_note->content().toStdString();
        note.__isset.content = true;
        note.contentLength = m_note->content().length();

        client()->updateNote(note, token().toStdString(), note);

    } catch (evernote::edam::EDAMUserException e) {
        errorCode = NotesStore::ErrorCodeUserException;
        qDebug() << QString::fromStdString(e.parameter);
    } catch (evernote::edam::EDAMSystemException) {
        errorCode = NotesStore::ErrorCodeSystemException;
    } catch (...) {
        catchTransportException();
        errorCode = NotesStore::ErrorCodeConnectionLost;
    }

    emit resultReady(errorCode, m_note);
}
