#ifndef FETCHNOTESJOB_H
#define FETCHNOTESJOB_H

#include "notesstorejob.h"

class FetchNotesJob : public NotesStoreJob
{
    Q_OBJECT
public:
    explicit FetchNotesJob(const QString &filterNotebookGuid, QObject *parent = 0);

signals:
    void jobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::NotesMetadataList &results);

protected:
    void startJob();
    void emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage);

private:
    QString m_filterNotebookGuid;
    evernote::edam::NotesMetadataList m_results;
};

#endif // FETCHNOTESJOB_H
