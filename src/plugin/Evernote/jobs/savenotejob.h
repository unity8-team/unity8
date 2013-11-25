#ifndef SAVENOTEJOB_H
#define SAVENOTEJOB_H

#include "evernotejob.h"

class SaveNoteJob : public EvernoteJob
{
    Q_OBJECT
public:
    explicit SaveNoteJob(Note *note, QObject *parent = 0);

    void run();
signals:
    void resultReady(NotesStore::ErrorCode errorCode, Note *note);

private:
    Note *m_note;
};

#endif // SAVENOTEJOB_H
