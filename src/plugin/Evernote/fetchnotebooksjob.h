#ifndef FETCHNOTEBOOKSJOB_H
#define FETCHNOTEBOOKSJOB_H

// Evernote SDK
#include <NoteStore.h>
#include <NoteStore_constants.h>
#include <Errors_types.h>

#include <QThread>

class FetchNotebooksJob : public QThread
{
    Q_OBJECT
public:
    explicit FetchNotebooksJob(std::vector<evernote::edam::Notebook> *results, evernote::edam::NoteStoreClient *client, const QString &token, QObject *parent = 0);

    void run();

signals:
    void resultReady();

private:
    std::vector<evernote::edam::Notebook> *m_results;
    evernote::edam::NoteStoreClient *m_client;
    QString m_token;
};

#endif // FETCHNOTEBOOKSJOB_H
