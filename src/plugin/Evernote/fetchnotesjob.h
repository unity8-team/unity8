#ifndef FETCHNOTESJOB_H
#define FETCHNOTESJOB_H

#include "notesstore.h"

// Evernote SDK
#include <NoteStore.h>
#include <NoteStore_constants.h>
#include <Errors_types.h>

#include <QThread>

class FetchNotesJob : public QThread
{
    Q_OBJECT
public:
    explicit FetchNotesJob(evernote::edam::NoteStoreClient *client, const QString &token, const QString &filterNotebookGuid, QObject *parent = 0);

    void run();

signals:
    void resultReady(NotesStore::ErrorCode errorCode, const evernote::edam::NotesMetadataList &results);

private:
    evernote::edam::NoteStoreClient *m_client;
    QString m_token;
    QString m_filterNotebookGuid;
};

#endif // FETCHNOTESJOB_H
