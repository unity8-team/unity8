#include "fetchnotejob.h"

FetchNoteJob::FetchNoteJob(evernote::edam::Note *result, evernote::edam::NoteStoreClient *client, const QString &token, const QString &guid, QObject *parent) :
    QThread(parent),
    m_result(result),
    m_client(client),
    m_token(token),
    m_guid(guid)
{
}

void FetchNoteJob::run()
{
    try {
        m_client->getNote(*m_result, m_token.toStdString(), m_guid.toStdString(), true, true, false, false);
    } catch(...) {
    }
    emit resultReady();
}
