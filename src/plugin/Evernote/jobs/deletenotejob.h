#ifndef DELETENOTEJOB_H
#define DELETENOTEJOB_H

#include "notesstorejob.h"

class DeleteNoteJob : public NotesStoreJob
{
    Q_OBJECT
public:
    DeleteNoteJob(const QString &guid, QObject *parent = 0);

signals:
    void jobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &guid);

protected:
    void startJob();
    void emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage);

private:
    QString m_guid;
};

#endif // DELETENOTEJOB_H
