#ifndef FETCHNOTESJOB_H
#define FETCHNOTESJOB_H

#include "evernotejob.h"

class FetchNotesJob : public EvernoteJob
{
    Q_OBJECT
public:
    explicit FetchNotesJob(const QString &filterNotebookGuid, QObject *parent = 0);

signals:
    void jobDone(NotesStore::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::NotesMetadataList &results);

protected:
    void startJob();
    void emitJobDone(NotesStore::ErrorCode errorCode, const QString &errorMessage);

private:
    QString m_filterNotebookGuid;
    evernote::edam::NotesMetadataList m_results;
};

#endif // FETCHNOTESJOB_H
