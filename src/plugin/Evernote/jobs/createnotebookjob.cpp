#include "createnotebookjob.h"

#include <QDebug>

CreateNotebookJob::CreateNotebookJob(const QString &name, QObject *parent) :
    NotesStoreJob(parent),
    m_name(name)
{
}

void CreateNotebookJob::startJob()
{
    m_result.name = m_name.toStdString();
    m_result.__isset.name = true;
    client()->createNotebook(m_result, token().toStdString(), m_result);
}

void CreateNotebookJob::emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage)
{
    emit jobDone(errorCode, errorMessage, m_result);
}
