#ifndef DELETENOTEJOB_H
#define DELETENOTEJOB_H

#include "evernotejob.h"

class DeleteNoteJob : public EvernoteJob
{
    Q_OBJECT
public:
    DeleteNoteJob(const QString &guid, QObject *parent = 0);

signals:
    void jobDone(NotesStore::ErrorCode errorCode, const QString &errorMessage, const QString &guid);

protected:
    void startJob();
    void emitJobDone(NotesStore::ErrorCode errorCode, const QString &errorMessage);

private:
    QString m_guid;
};

#endif // DELETENOTEJOB_H
