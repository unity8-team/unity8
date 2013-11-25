#ifndef DELETENOTEJOB_H
#define DELETENOTEJOB_H

#include "evernotejob.h"

class DeleteNoteJob : public EvernoteJob
{
    Q_OBJECT
public:
    DeleteNoteJob(const QString &guid, QObject *parent = 0);

    void run();

signals:
    void resultReady(NotesStore::ErrorCode errorCode, const QString &guid);

private:
    QString m_guid;
};

#endif // DELETENOTEJOB_H
