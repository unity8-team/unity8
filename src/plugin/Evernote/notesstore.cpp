/*
 * Copyright: 2013 Canonical, Ltd
 *
 * This file is part of reminders-app
 *
 * reminders-app is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
 */

#include "notesstore.h"
#include "notebooks.h"
#include "notebook.h"
#include "note.h"
#include "utils/html2enmlconverter.h"

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
        bool use_SSL = true;

        if (use_SSL) {
            // Create an SSL socket
            // FIXME: this fails with the following error:
            //   Thrift: Fri Nov 15 12:47:31 2013 SSL_shutdown: error code: 0
            //   SSL_get_verify_result(), unable to get local issuer certificate
            // Additionally, the UI blocks and does not load for about 2 minutes
            boost::shared_ptr<TSSLSocketFactory> sslSocketFactory(new TSSLSocketFactory());
            socket = sslSocketFactory->createSocket(EVERNOTE_HOST.toStdString(), 443);
            qDebug() << "created SSL socket";
        } else {
            // Create a non-secure socket
            socket = boost::shared_ptr<TSocket> (new TSocket(EVERNOTE_HOST.toStdString(), 80));
            qDebug() << "created insecure socket";
        }

        boost::shared_ptr<TBufferedTransport> bufferedTransport(new TBufferedTransport(socket));
        m_httpClient = boost::shared_ptr<THttpClient>(new THttpClient(bufferedTransport,
                                                                            EVERNOTE_HOST.toStdString(),
                                                                            EDAM_USER_STORE_PATH.toStdString()));
        m_httpClient->open();

        boost::shared_ptr<TProtocol> iprot(new TBinaryProtocol(m_httpClient));
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

QList<Notebook *> NotesStore::notebooks() const
{
    return m_notebooks.values();
}

Notebook *NotesStore::notebook(const QString &guid)
{
    return m_notebooks.value(guid);
}

void NotesStore::enqueue(EvernoteJob *job)
{
    m_jobQueue.append(job);
    startJobQueue();
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
    FetchNotesJob *job = new FetchNotesJob(filterNotebookGuid);
    connect(job, &FetchNotesJob::jobDone, this, &NotesStore::fetchNotesJobDone);
    enqueue(job);
}

void NotesStore::fetchNotesJobDone(ErrorCode errorCode, const QString &errorMessage, const evernote::edam::NotesMetadataList &results)
{
    if (errorCode != ErrorCodeNoError) {
        qWarning() << "Failed to fetch notes list:" << errorMessage;
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
}

void NotesStore::refreshNoteContent(const QString &guid)
{
    FetchNoteJob *job = new FetchNoteJob(guid, this);
    connect(job, &FetchNoteJob::resultReady, this, &NotesStore::fetchNoteJobDone);
    enqueue(job);
}

void NotesStore::fetchNoteJobDone(ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result)
{
    if (errorCode != ErrorCodeNoError) {
        qWarning() << "Error fetching note:" << errorMessage;
        return;
    }

    Note *note = m_notes.value(QString::fromStdString(result.guid));
    note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
    note->setTitle(QString::fromStdString(result.title));
    note->setContent(QString::fromStdString(result.content));
    emit noteChanged(note->guid());
}

void NotesStore::refreshNotebooks()
{
    FetchNotebooksJob *job = new FetchNotebooksJob();
    connect(job, &FetchNotebooksJob::jobDone, this, &NotesStore::fetchNotebooksJobDone);
    enqueue(job);
}

void NotesStore::fetchNotebooksJobDone(ErrorCode errorCode, const QString &errorMessage, const std::vector<evernote::edam::Notebook> &results)
{
    if (errorCode != ErrorCodeNoError) {
        qWarning() << "Error fetching notebooks:" << errorMessage;
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
}

void NotesStore::createNote(const QString &title, const QString &notebookGuid, const QString &content)
{
    CreateNoteJob *job = new CreateNoteJob(title, notebookGuid, content);
    connect(job, &CreateNoteJob::jobDone, this, &NotesStore::createNoteJobDone);
    enqueue(job);
}

void NotesStore::createNoteJobDone(NotesStore::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result)
{
    if (errorCode != ErrorCodeNoError) {
        qWarning() << "Error creating note:" << errorMessage;
        return;
    }

    Note *note = new Note(QString::fromStdString(result.guid));
    note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
    note->setTitle(QString::fromStdString(result.title));
    note->setContent(QString::fromStdString(result.content));

    m_notes.insert(note->guid(), note);
    noteAdded(note->guid());
}

void NotesStore::saveNote(const QString &guid)
{
    Note *note = m_notes.value(guid);

    QString enml = Html2EnmlConverter::html2enml(note->content());
    note->setContent(enml);

    SaveNoteJob *job = new SaveNoteJob(note, this);
    connect(job, &SaveNoteJob::jobDone, this, &NotesStore::saveNoteJobDone);
    enqueue(job);
}

void NotesStore::saveNoteJobDone(NotesStore::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result)
{
    if (errorCode != ErrorCodeNoError) {
        qWarning() << "error saving note" << errorMessage;
        return;
    }

    Note *note = m_notes.value(QString::fromStdString(result.guid));
    if (note) {
        note->setTitle(QString::fromStdString(result.title));
        note->setNotebookGuid(QString::fromStdString(result.notebookGuid));

        emit noteChanged(note->guid());
    }
}

void NotesStore::deleteNote(const QString &guid)
{
    DeleteNoteJob *job = new DeleteNoteJob(guid, this);
    connect(job, &DeleteNoteJob::jobDone, this, &NotesStore::deleteNoteJobDone);
    enqueue(job);
}

void NotesStore::deleteNoteJobDone(NotesStore::ErrorCode errorCode, const QString &errorMessage, const QString &guid)
{
    if (errorCode != ErrorCodeNoError) {
        qWarning() << "Cannot delete note:" << errorMessage;
        return;
    }
    emit noteRemoved(guid);
    m_notes.take(guid)->deleteLater();
}
