#include "evernotejob.h"

// Thrift
#include <arpa/inet.h> // seems thrift forgot this one
#include <protocol/TBinaryProtocol.h>
#include <transport/THttpClient.h>
#include <transport/TSSLSocket.h>
#include <Thrift.h>

#include <QDebug>

using namespace apache::thrift;
using namespace apache::thrift::protocol;
using namespace apache::thrift::transport;

EvernoteJob::EvernoteJob(QObject *parent) :
    QThread(parent),
    m_token(NotesStore::instance()->token())
{
    connect(this, &EvernoteJob::finished, this, &EvernoteJob::deleteLater);
}

EvernoteJob::~EvernoteJob()
{

}

evernote::edam::NoteStoreClient *EvernoteJob::client()
{
    return NotesStore::instance()->m_client;
}

QString EvernoteJob::token()
{
    return m_token;
}

void EvernoteJob::catchTransportException()
{
    try {
        // this function is meant to be called from a catch block
        // rethrow the exception to catch it again
        throw;
    } catch (const TTransportException & e) {
        qDebug() <<  e.what();
    } catch (const TException & e) {
        qDebug() <<  e.what();
    }
}
