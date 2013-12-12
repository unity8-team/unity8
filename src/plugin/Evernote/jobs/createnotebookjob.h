#ifndef CREATENOTEBOOKJOB_H
#define CREATENOTEBOOKJOB_H

#include "notesstorejob.h"

class CreateNotebookJob : public NotesStoreJob
{
    Q_OBJECT
public:
    explicit CreateNotebookJob(const QString &name, QObject *parent = 0);

    virtual void startJob() override;

signals:
    void jobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Notebook &result);

private slots:
    void emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage);

private:
    QString m_name;

    evernote::edam::Notebook m_result;
};

#endif // CREATENOTEBOOKJOB_H
