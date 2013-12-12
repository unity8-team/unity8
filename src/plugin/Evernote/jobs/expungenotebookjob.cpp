#include "expungenotebookjob.h"

#include <QDebug>

ExpungeNotebookJob::ExpungeNotebookJob(const QString &guid, QObject *parent) :
    NotesStoreJob(parent),
    m_guid(guid)
{
}

void ExpungeNotebookJob::startJob()
{
    client()->expungeNotebook(token().toStdString(), m_guid.toStdString());
}

void ExpungeNotebookJob::emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage)
{
    emit jobDone(errorCode, errorMessage, m_guid);
}
