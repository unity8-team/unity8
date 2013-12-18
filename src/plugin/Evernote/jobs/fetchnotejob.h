#ifndef FETCHNOTEJOB_H
#define FETCHNOTEJOB_H

#include "notesstorejob.h"

class FetchNoteJob : public NotesStoreJob
{
    Q_OBJECT
public:
    explicit FetchNoteJob(const QString &guid, QObject *parent = 0);

signals:
    void resultReady(EvernoteConnection::ErrorCode error, const QString &errorMessage, const evernote::edam::Note &note);

protected:
    void startJob();
    void emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage);

private:
    evernote::edam::NoteStoreClient *m_client;
    QString m_token;
    QString m_guid;

    evernote::edam::Note m_result;

};

#endif // FETCHNOTEJOB_H
