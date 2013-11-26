#ifndef FETCHNOTEJOB_H
#define FETCHNOTEJOB_H

#include "notesstore.h"

// Evernote SDK
#include <NoteStore.h>
#include <NoteStore_constants.h>
#include <Errors_types.h>

#include <QThread>

class FetchNoteJob : public QThread
{
    Q_OBJECT
public:
    explicit FetchNoteJob(evernote::edam::NoteStoreClient *client, const QString &token, const QString &guid, QObject *parent = 0);

    void run();
signals:
    void resultReady(NotesStore::ErrorCode error, const evernote::edam::Note &note);

private:
    evernote::edam::NoteStoreClient *m_client;
    QString m_token;
    QString m_guid;
};

#endif // FETCHNOTEJOB_H
