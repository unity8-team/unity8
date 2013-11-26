#ifndef FETCHNOTEJOB_H
#define FETCHNOTEJOB_H

#include "evernotejob.h"

class FetchNoteJob : public EvernoteJob
{
    Q_OBJECT
public:
    explicit FetchNoteJob(const QString &guid, QObject *parent = 0);

    void run();
signals:
    void resultReady(NotesStore::ErrorCode error, const evernote::edam::Note &note);

private:
    evernote::edam::NoteStoreClient *m_client;
    QString m_token;
    QString m_guid;
};

#endif // FETCHNOTEJOB_H
