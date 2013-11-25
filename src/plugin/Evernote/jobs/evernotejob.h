#ifndef EVERNOTEJOB_H
#define EVERNOTEJOB_H

#include "notesstore.h"

// Evernote SDK
#include <NoteStore.h>
#include <NoteStore_constants.h>
#include <Errors_types.h>

#include <QThread>

class EvernoteJob : public QThread
{
    Q_OBJECT
public:
    explicit EvernoteJob(QObject *parent = 0);
    virtual ~EvernoteJob();

protected:
    evernote::edam::NoteStoreClient* client();
    QString token();

    void catchTransportException();

private:
    QString m_token;
};

#endif // EVERNOTEJOB_H
