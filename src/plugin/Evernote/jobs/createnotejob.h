#ifndef CREATENOTEJOB_H
#define CREATENOTEJOB_H

#include "evernotejob.h"
#include "note.h"

class CreateNoteJob : public EvernoteJob
{
    Q_OBJECT
public:
    explicit CreateNoteJob(Note *note, QObject *parent = 0);

    void run();

signals:
    void resultReady(NotesStore::ErrorCode errorCode, Note *note);

private:
    Note *m_note;
};

#endif // CREATENOTEJOB_H
