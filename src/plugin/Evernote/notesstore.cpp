#include "notesstore.h"
#include "notebooks.h"
#include "notebook.h"
#include "note.h"

#include "fetchnotesjob.h"
#include "fetchnotebooksjob.h"
#include "fetchnotejob.h"

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

NotesStore* NotesStore::s_instance = 0;

NotesStore::NotesStore(QObject *parent) :
    QObject(parent),
    m_currentJob(0)
{
    try {
        // TODO: Move this to a common place instead of keeping a copy here and in UserStore

        // FIXME: need to populate this string from the system
        // The structure should be:
        // application/version; platform/version; [ device/version ]
        // E.g. "Evernote Windows/3.0.1; Windows/XP SP3"
        QString EDAM_CLIENT_NAME = QStringLiteral("Reminders/0.1; Ubuntu/13.10");
        QString EVERNOTE_HOST = QStringLiteral("sandbox.evernote.com");
        QString EDAM_USER_STORE_PATH = QStringLiteral("/edam/note");
        boost::shared_ptr<TSocket> socket;
        bool use_SSL = false;

        if (use_SSL) {
            // Create an SSL socket
            // FIXME: this fails with the following error:
            //   Thrift: Fri Nov 15 12:47:31 2013 SSL_shutdown: error code: 0
            //   SSL_get_verify_result(), unable to get local issuer certificate
            // Additionally, the UI blocks and does not load for about 2 minutes
            boost::shared_ptr<TSSLSocketFactory> sslSocketFactory(new TSSLSocketFactory());
            socket = sslSocketFactory->createSocket(EVERNOTE_HOST.toStdString(), 443);
        } else {
            // Create a non-secure socket
            socket = boost::shared_ptr<TSocket> (new TSocket(EVERNOTE_HOST.toStdString(), 80));
        }

        boost::shared_ptr<TBufferedTransport> bufferedTransport(new TBufferedTransport(socket));
        boost::shared_ptr<THttpClient> userStoreHttpClient (new THttpClient(bufferedTransport,
                                                                            EVERNOTE_HOST.toStdString(),
                                                                            EDAM_USER_STORE_PATH.toStdString()));
        userStoreHttpClient->open();

        boost::shared_ptr<TProtocol> iprot(new TBinaryProtocol(userStoreHttpClient));
        m_client = new evernote::edam::NoteStoreClient(iprot);

        qDebug() << "NoteStore client created.";
    } catch(...) {
        displayException();
    }

}

NotesStore *NotesStore::instance()
{
    if (!s_instance) {
        s_instance = new NotesStore();
    }
    return s_instance;
}

NotesStore::~NotesStore()
{
    delete m_client;
}

QString NotesStore::token() const
{
    return m_token;
}

void NotesStore::setToken(const QString &token)
{
    if (token != m_token) {
        m_token = token;
        emit tokenChanged();
        refreshNotebooks();
        refreshNotes();
    }
}

QList<Note*> NotesStore::notes() const
{
    return m_notes.values();
}

Note *NotesStore::note(const QString &guid)
{
    return m_notes.value(guid);
}

QList<Notebook *> NotesStore::notebooks() const
{
    return m_notebooks.values();
}

Notebook *NotesStore::notebook(const QString &guid)
{
    return m_notebooks.value(guid);
}

void NotesStore::refreshNotes(const QString &filterNotebookGuid)
{
    if (m_token.isEmpty()) {
        qDebug() << "No token set. Cannot fetch notes.";
        return;
    }

    evernote::edam::NotesMetadataList *resultList = new evernote::edam::NotesMetadataList;
    FetchNotesJob *job = new FetchNotesJob(resultList, m_client, m_token, filterNotebookGuid);
    m_notesResultsMap.insert(job, resultList);
    connect(job, SIGNAL(resultReady()), SLOT(fetchNotesJobDone()));
    m_requestQueue.append(job);
    sendNextRequest();
}

void NotesStore::fetchNotesJobDone()
{
    evernote::edam::NotesMetadataList *results = m_notesResultsMap.take(sender());

    for (int i = 0; i < results->notes.size(); ++i) {
        evernote::edam::NoteMetadata result = results->notes.at(i);
        Note *note = m_notes.value(QString::fromStdString(result.guid));
        if (note) {
            qDebug() << "Received update for existing note";
        } else {
            note = new Note(QString::fromStdString(result.guid), this);
            note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
            note->setTitle(QString::fromStdString(result.title));
            m_notes.insert(note->guid(), note);
            emit noteAdded(note->guid());
        }
    }
    delete results;
    delete sender();
    m_currentJob = 0;
    sendNextRequest();
}

void NotesStore::refreshNoteContent(const QString &guid)
{
    if (m_token.isEmpty()) {
        return;
    }

    evernote::edam::Note *result = new evernote::edam::Note;
    FetchNoteJob *job = new FetchNoteJob(result, m_client, m_token, guid, this);
    m_noteContentResultsMap.insert(job, result);
    connect(job, SIGNAL(resultReady()), SLOT(fetchNoteJobDone()));
    m_requestQueue.append(job);
    sendNextRequest();
}

void NotesStore::fetchNoteJobDone()
{
    evernote::edam::Note *result = m_noteContentResultsMap.take(sender());
    Note *note = m_notes.value(QString::fromStdString(result->guid));
    note->setNotebookGuid(QString::fromStdString(result->notebookGuid));
    note->setTitle(QString::fromStdString(result->title));
    note->setContent(QString::fromStdString(result->content));
    emit noteChanged(note->guid());

    delete result;
    delete sender();
    m_currentJob = 0;
    sendNextRequest();
}

void NotesStore::refreshNotebooks()
{
    if (m_token.isEmpty()) {
        qDebug() << "No token set. Cannot refresh notebooks.";
        return;
    }

    std::vector<evernote::edam::Notebook> *results = new std::vector<evernote::edam::Notebook>;
    FetchNotebooksJob *job = new FetchNotebooksJob(results, m_client, m_token);
    connect(job, SIGNAL(resultReady()), SLOT(fetchNotebooksJobDone()));
    m_notebooksResultsMap.insert(job, results);
    m_requestQueue.append(job);
    sendNextRequest();
}

void NotesStore::fetchNotebooksJobDone()
{
    std::vector<evernote::edam::Notebook> *results = m_notebooksResultsMap.take(sender());

    for (int i = 0; i < results->size(); ++i) {
        evernote::edam::Notebook result = results->at(i);
        Notebook *notebook = m_notebooks.value(QString::fromStdString(result.guid));
        if (notebook) {
            qDebug() << "got notebook update";
        } else {
            notebook = new Notebook(QString::fromStdString(result.guid), this);
            notebook->setName(QString::fromStdString(result.name));
            m_notebooks.insert(notebook->guid(), notebook);
            emit notebookAdded(notebook->guid());
        }
    }
    delete results;
    delete sender();
    m_currentJob = 0;
    sendNextRequest();
}

void NotesStore::sendNextRequest()
{
    if (m_requestQueue.isEmpty()) {
        return;
    }

    if (m_currentJob) {
        return;
    }
    m_currentJob = m_requestQueue.takeFirst();
    m_currentJob->start();
}

// TODO: move to a common place instead of copying it through *store.cpps
void NotesStore::displayException()
{
    QString error_message = "Unknown Exception";
    try
    {
        // this function is meant to be called from a catch block
        // rethrow the exception to catch it again
        throw;
    }
    catch (const evernote::edam::EDAMNotFoundException & e)
    {
        qDebug() <<  e.what();
    }
    catch (const evernote::edam::EDAMSystemException & e)
    {
        qDebug() <<  e.what();
    }
    catch (const evernote::edam::EDAMUserException & e)
    {
        qDebug() <<  e.what();
    }
    catch (const TTransportException & e)
    {
        qDebug() <<  e.what();
    }
    catch (const TException & e)
    {
        qDebug() <<  e.what();
    }
    catch (const std::exception & e)
    {
        qDebug() <<  e.what();
    }
    catch (...)
    {
        error_message = "Tried to sync, but something went wrong.\n Unknown exception.";
    }

    qDebug() << error_message;
    disconnect();
}
