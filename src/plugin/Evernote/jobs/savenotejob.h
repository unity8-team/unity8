#ifndef SAVENOTEJOB_H
#define SAVENOTEJOB_H

#include "notesstorejob.h"

class SaveNoteJob : public NotesStoreJob
{
    Q_OBJECT
public:
    explicit SaveNoteJob(Note *note, QObject *parent = 0);

signals:
    void jobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &note);

protected:
    void startJob();
    void emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage);

private:
    Note* m_note;
    evernote::edam::Note m_resultNote;
};

#endif // SAVENOTEJOB_H
