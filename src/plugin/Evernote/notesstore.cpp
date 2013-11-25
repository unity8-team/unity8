#include "notesstore.h"
#include "notebooks.h"
#include "notebook.h"
#include "note.h"

#include "jobs/fetchnotesjob.h"
#include "jobs/fetchnotebooksjob.h"
#include "jobs/fetchnotejob.h"
#include "jobs/createnotejob.h"
#include "jobs/savenotejob.h"
#include "jobs/deletenotejob.h"

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

    } catch (const TTransportException & e) {
        qWarning() << "Failed to create Transport:" <<  e.what();
    } catch (const TException & e) {
        qWarning() << "Generic Thrift exception:" << e.what();
    }

    qRegisterMetaType<NotesStore::ErrorCode>("NotesStore::ErrorCode");
    qRegisterMetaType<evernote::edam::NotesMetadataList>("evernote::edam::NotesMetadataList");
    qRegisterMetaType<evernote::edam::Note>("evernote::edam::Note");
    qRegisterMetaType<std::vector<evernote::edam::Notebook> >("std::vector<evernote::edam::Notebook>");

}

NotesStore *NotesStore::instance()
{
    if (!s_instance) {
        s_instance = new NotesStore();
    }
    return s_instance;
}

QString NotesStore::errorCodeToString(NotesStore::ErrorCode errorCode)
{
    switch(errorCode) {
    case ErrorCodeNoError:
        return QStringLiteral("No error");
    case ErrorCodeUserException:
        return QStringLiteral("User exception");
    case ErrorCodeSystemException:
        return QStringLiteral("System exception");
    case ErrorCodeNotFoundExcpetion:
        return QStringLiteral("Not found");
    }
    return QString();
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

void NotesStore::saveNote(const QString &guid)
{
    Note *note = m_notes.value(guid);
    SaveNoteJob *job = new SaveNoteJob(note, this);
    connect(job, &SaveNoteJob::resultReady, this, &NotesStore::saveNoteJobDone);
    m_jobQueue.append(job);
    startJobQueue();
}

void NotesStore::deleteNote(const QString &guid)
{
    DeleteNoteJob *job = new DeleteNoteJob(guid, this);
    connect(job, &DeleteNoteJob::resultReady, this, &NotesStore::deleteNoteJobDone);
    m_jobQueue.append(job);
    startJobQueue();
}

QList<Notebook *> NotesStore::notebooks() const
{
    return m_notebooks.values();
}

Notebook *NotesStore::notebook(const QString &guid)
{
    return m_notebooks.value(guid);
}

void NotesStore::startJobQueue()
{
    if (m_jobQueue.isEmpty()) {
        return;
    }

    if (m_currentJob) {
        return;
    }
    m_currentJob = m_jobQueue.takeFirst();
    m_currentJob->start();
}

void NotesStore::startNextJob()
{
    m_currentJob = 0;
    startJobQueue();
}

void NotesStore::refreshNotes(const QString &filterNotebookGuid)
{
    if (m_token.isEmpty()) {
        qWarning() << "No token set. Cannot fetch notes.";
        return;
    }

    FetchNotesJob *job = new FetchNotesJob(filterNotebookGuid);
    connect(job, &FetchNotesJob::resultReady, this, &NotesStore::fetchNotesJobDone);

    m_jobQueue.append(job);
    startJobQueue();
}

void NotesStore::fetchNotesJobDone(ErrorCode errorCode, const evernote::edam::NotesMetadataList &results)
{
    if (errorCode != ErrorCodeNoError) {
        qWarning() << "Failed to fetch notes list:" << errorCodeToString(errorCode);
        startNextJob();
        return;
    }

    for (int i = 0; i < results.notes.size(); ++i) {
        evernote::edam::NoteMetadata result = results.notes.at(i);
        Note *note = m_notes.value(QString::fromStdString(result.guid));
        if (note) {
            note->setTitle(QString::fromStdString(result.title));
            note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
            emit noteChanged(note->guid());
        } else {
            note = new Note(QString::fromStdString(result.guid), this);
            note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
            note->setTitle(QString::fromStdString(result.title));
            m_notes.insert(note->guid(), note);
            emit noteAdded(note->guid());
        }
    }

    startNextJob();
}

void NotesStore::refreshNoteContent(const QString &guid)
{
    if (m_token.isEmpty()) {
        qWarning() << "No token set. Cannot fetch note.";
        return;
    }

    FetchNoteJob *job = new FetchNoteJob(guid, this);
    connect(job, &FetchNoteJob::resultReady, this, &NotesStore::fetchNoteJobDone);
    m_jobQueue.append(job);

    startJobQueue();
}

void NotesStore::fetchNoteJobDone(ErrorCode errorCode, const evernote::edam::Note &result)
{
    if (errorCode != ErrorCodeNoError) {
        qWarning() << "Error fetching note:" << errorCode;
        startNextJob();
        return;
    }

    Note *note = m_notes.value(QString::fromStdString(result.guid));
    note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
    note->setTitle(QString::fromStdString(result.title));
    note->setContent(QString::fromStdString(result.content));
    emit noteChanged(note->guid());

    startNextJob();
}

void NotesStore::refreshNotebooks()
{
    if (m_token.isEmpty()) {
        qWarning() << "No token set. Cannot refresh notebooks.";
        return;
    }

    FetchNotebooksJob *job = new FetchNotebooksJob();
    connect(job, &FetchNotebooksJob::resultReady, this, &NotesStore::fetchNotebooksJobDone);

    m_jobQueue.append(job);
    startJobQueue();
}

void NotesStore::fetchNotebooksJobDone(ErrorCode errorCode, const std::vector<evernote::edam::Notebook> &results)
{
    if (errorCode != ErrorCodeNoError) {
        qWarning() << "Error fetching notebooks:" << errorCodeToString(errorCode);
        startNextJob();
        return;
    }

    for (int i = 0; i < results.size(); ++i) {
        evernote::edam::Notebook result = results.at(i);
        Notebook *notebook = m_notebooks.value(QString::fromStdString(result.guid));
        if (notebook) {
            qDebug() << "got notebook update";
            notebook->setName(QString::fromStdString(result.name));
            emit notebookChanged(notebook->guid());
        } else {
            notebook = new Notebook(QString::fromStdString(result.guid), this);
            notebook->setName(QString::fromStdString(result.name));
            m_notebooks.insert(notebook->guid(), notebook);
            emit notebookAdded(notebook->guid());
            qDebug() << "got new notebook" << notebook->guid();
        }
    }

    startNextJob();
}

void NotesStore::createNote(const QString &title, const QString &notebookGuid, const QString &content)
{
    Note *note = new Note();
    note->setTitle(title);
    note->setNotebookGuid(notebookGuid);
    note->setContent(content);
    CreateNoteJob *job = new CreateNoteJob(note);
    connect(job, &CreateNoteJob::resultReady, this, &NotesStore::createNoteJobDone);

    m_jobQueue.append(job);
    startJobQueue();
}

void NotesStore::createNoteJobDone(NotesStore::ErrorCode errorCode, Note *note)
{
    if (errorCode != ErrorCodeNoError) {
        qWarning() << "Error creating note:" << errorCodeToString(errorCode);
        delete note;
        startNextJob();
        return;
    }

    m_notes.insert(note->guid(), note);
    noteAdded(note->guid());
    startNextJob();
}

void NotesStore::saveNoteJobDone(NotesStore::ErrorCode errorCode, Note *note)
{
    startNextJob();
}

void NotesStore::deleteNoteJobDone(NotesStore::ErrorCode errorCode, const QString &guid)
{
    if (errorCode != ErrorCodeNoError) {
        qWarning() << "Cannot delete note:" << errorCodeToString(errorCode);
        startNextJob();
        return;
    }
    emit noteRemoved(guid);
    m_notes.take(guid)->deleteLater();
    startNextJob();
}

