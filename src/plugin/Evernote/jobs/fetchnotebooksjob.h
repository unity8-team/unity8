#ifndef FETCHNOTEBOOKSJOB_H
#define FETCHNOTEBOOKSJOB_H

#include "notesstorejob.h"

class FetchNotebooksJob : public NotesStoreJob
{
    Q_OBJECT
public:
    explicit FetchNotebooksJob(QObject *parent = 0);

signals:
    void jobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const std::vector<evernote::edam::Notebook> &results);

protected:
    void startJob();
    void emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage);

private:
    std::vector<evernote::edam::Notebook> m_results;
};

#endif // FETCHNOTEBOOKSJOB_H
