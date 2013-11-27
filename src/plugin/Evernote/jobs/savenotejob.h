#ifndef SAVENOTEJOB_H
#define SAVENOTEJOB_H

#include "evernotejob.h"

class SaveNoteJob : public EvernoteJob
{
    Q_OBJECT
public:
    explicit SaveNoteJob(Note *note, QObject *parent = 0);

signals:
    void jobDone(NotesStore::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &note);

protected:
    void startJob();
    void emitJobDone(NotesStore::ErrorCode errorCode, const QString &errorMessage);

private:
    QString m_guid;
    QString m_title;
    QString m_notebookGuid;
    QString m_content;

    evernote::edam::Note m_note;
};

#endif // SAVENOTEJOB_H
