#ifndef FETCHNOTEBOOKSJOB_H
#define FETCHNOTEBOOKSJOB_H

#include "evernotejob.h"

class FetchNotebooksJob : public EvernoteJob
{
    Q_OBJECT
public:
    explicit FetchNotebooksJob(QObject *parent = 0);

    void run();

signals:
    void resultReady(NotesStore::ErrorCode errorCode, const std::vector<evernote::edam::Notebook> &results);
};

#endif // FETCHNOTEBOOKSJOB_H
