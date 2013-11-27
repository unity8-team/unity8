#ifndef FETCHNOTEBOOKSJOB_H
#define FETCHNOTEBOOKSJOB_H

#include "evernotejob.h"

class FetchNotebooksJob : public EvernoteJob
{
    Q_OBJECT
public:
    explicit FetchNotebooksJob(QObject *parent = 0);

signals:
    void jobDone(NotesStore::ErrorCode errorCode, const QString &errorMessage, const std::vector<evernote::edam::Notebook> &results);

protected:
    void startJob();
    void emitJobDone(NotesStore::ErrorCode errorCode, const QString &errorMessage);

private:
    std::vector<evernote::edam::Notebook> m_results;
};

#endif // FETCHNOTEBOOKSJOB_H
