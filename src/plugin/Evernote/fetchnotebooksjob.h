#ifndef FETCHNOTEBOOKSJOB_H
#define FETCHNOTEBOOKSJOB_H

#include "notesstore.h"

// Evernote SDK
#include <NoteStore.h>
#include <NoteStore_constants.h>
#include <Errors_types.h>

#include <QThread>

class FetchNotebooksJob : public QThread
{
    Q_OBJECT
public:
    explicit FetchNotebooksJob(evernote::edam::NoteStoreClient *client, const QString &token, QObject *parent = 0);

    void run();

signals:
    void resultReady(NotesStore::ErrorCode errorCode, const std::vector<evernote::edam::Notebook> &results);

private:
    evernote::edam::NoteStoreClient *m_client;
    QString m_token;
};

#endif // FETCHNOTEBOOKSJOB_H
