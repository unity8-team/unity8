#ifndef FETCHNOTESJOB_H
#define FETCHNOTESJOB_H

#include "evernotejob.h"

class FetchNotesJob : public EvernoteJob
{
    Q_OBJECT
public:
    explicit FetchNotesJob(const QString &filterNotebookGuid, QObject *parent = 0);

    void run();

signals:
    void resultReady(NotesStore::ErrorCode errorCode, const evernote::edam::NotesMetadataList &results);

private:
    QString m_filterNotebookGuid;
};

#endif // FETCHNOTESJOB_H
