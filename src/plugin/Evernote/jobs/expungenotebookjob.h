#ifndef DELETENOTEBOOKJOB_H
#define DELETENOTEBOOKJOB_H

#include "notesstorejob.h"

class ExpungeNotebookJob : public NotesStoreJob
{
    Q_OBJECT
public:
    explicit ExpungeNotebookJob(const QString &guid, QObject *parent = 0);

signals:
    void jobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &guid);

private slots:
    void startJob();
    void emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage);

private:
    QString m_guid;
};

#endif // DELETENOTEBOOKJOB_H
