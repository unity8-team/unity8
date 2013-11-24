#ifndef FETCHNOTEJOB_H
#define FETCHNOTEJOB_H

// Evernote SDK
#include <NoteStore.h>
#include <NoteStore_constants.h>
#include <Errors_types.h>

#include <QThread>

class FetchNoteJob : public QThread
{
    Q_OBJECT
public:
    explicit FetchNoteJob(evernote::edam::Note *result, evernote::edam::NoteStoreClient *client, const QString &token, const QString &guid, QObject *parent = 0);

    void run();
signals:
    void resultReady();

private:
    evernote::edam::Note *m_result;
    evernote::edam::NoteStoreClient *m_client;
    QString m_token;
    QString m_guid;
};

#endif // FETCHNOTEJOB_H
