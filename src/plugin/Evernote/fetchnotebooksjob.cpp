#include "fetchnotebooksjob.h"

#include <QDebug>

FetchNotebooksJob::FetchNotebooksJob(std::vector<evernote::edam::Notebook> *results, evernote::edam::NoteStoreClient *client, const QString &token, QObject *parent) :
    QThread(parent),
    m_results(results),
    m_client(client),
    m_token(token)
{
}


void FetchNotebooksJob::run()
{
    try {
        m_client->listNotebooks(*m_results, m_token.toStdString());
    } catch (...) {
        qDebug() << "Error fetching notebooks";
    }
    emit resultReady();

}
