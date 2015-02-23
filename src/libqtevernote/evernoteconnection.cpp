/*
 * Copyright: 2013 - 2014 Canonical, Ltd
 *
 * This file is part of reminders
 *
 * reminders is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
 *          Riccardo Padovani <rpadovani@ubuntu.com>
 */

#include "evernoteconnection.h"
#include "jobs/evernotejob.h"

// Thrift
#include <arpa/inet.h> // seems thrift forgot this one
#include <protocol/TBinaryProtocol.h>
#include <transport/THttpClient.h>
#include <transport/TSSLSocket.h>
#include <Thrift.h>

// Evernote SDK
#include <NoteStore.h>
#include <NoteStore_constants.h>
#include <UserStore.h>
#include <UserStore_constants.h>
#include <Errors_types.h>

#include <QDebug>
#include <QUrl>

#include <libintl.h>

using namespace apache::thrift;
using namespace apache::thrift::protocol;
using namespace apache::thrift::transport;

EvernoteConnection* EvernoteConnection::s_instance = 0;

// FIXME: need to populate this string from the system
// The structure should be:
// application/version; platform/version; [ device/version ]
// E.g. "Evernote Windows/3.0.1; Windows/XP SP3"
QString EDAM_CLIENT_NAME = QStringLiteral("Reminders/0.4; Ubuntu/14.10");
QString EDAM_USER_STORE_PATH = QStringLiteral("/edam/user");

EvernoteConnection::EvernoteConnection(QObject *parent) :
    QObject(parent),
    m_useSSL(true),
    m_isConnected(false),
    m_currentJob(0),
    m_notesStoreClient(0),
    m_notesStoreHttpClient(0),
    m_userstoreClient(0),
    m_userStoreHttpClient(0)
{
    qRegisterMetaType<EvernoteConnection::ErrorCode>("EvernoteConnection::ErrorCode");
}

void EvernoteConnection::setupUserStore()
{
    if (m_userstoreClient != 0) {
        delete m_userstoreClient;
        m_userStoreHttpClient.reset();
    }

    boost::shared_ptr<TSocket> socket;

    if (m_useSSL) {
        boost::shared_ptr<TSSLSocketFactory> sslSocketFactory(new TSSLSocketFactory());
        socket = sslSocketFactory->createSocket(m_hostname.toStdString(), 443);
        qDebug() << "created UserStore SSL socket to host " << m_hostname;
    } else {
        // Create a non-secure socket
        socket = boost::shared_ptr<TSocket> (new TSocket(m_hostname.toStdString(), 80));
        qDebug() << "created insecure UserStore socket to host " << m_hostname;
    }

    // setup UserStore client
    boost::shared_ptr<TBufferedTransport> bufferedTransport(new TBufferedTransport(socket));
    m_userStoreHttpClient = boost::shared_ptr<THttpClient>(new THttpClient(bufferedTransport,
                                                                        m_hostname.toStdString(),
                                                                        EDAM_USER_STORE_PATH.toStdString()));

    boost::shared_ptr<TProtocol> userstoreiprot(new TBinaryProtocol(m_userStoreHttpClient));
    m_userstoreClient = new evernote::edam::UserStoreClient(userstoreiprot);
}

void EvernoteConnection::setupNotesStore()
{
    if (m_notesStoreClient != 0) {
        delete m_notesStoreClient;
        m_notesStoreHttpClient.reset();
    }

    boost::shared_ptr<TSocket> socket;

    if (m_useSSL) {
        boost::shared_ptr<TSSLSocketFactory> sslSocketFactory(new TSSLSocketFactory());
        socket = sslSocketFactory->createSocket(m_hostname.toStdString(), 443);
        qDebug() << "created NotesStore SSL socket to host " << m_hostname;
    } else {
        // Create a non-secure socket
        socket = boost::shared_ptr<TSocket> (new TSocket(m_hostname.toStdString(), 80));
        qDebug() << "created insecure NotesStore socket to host " << m_hostname;
    }

    // setup NotesStore client
    boost::shared_ptr<TBufferedTransport> bufferedTransport(new TBufferedTransport(socket));
    m_notesStoreHttpClient = boost::shared_ptr<THttpClient>(new THttpClient(bufferedTransport,
                                                                        m_hostname.toStdString(),
                                                                        m_notesStorePath.toStdString()));

    boost::shared_ptr<TProtocol> notesstoreiprot(new TBinaryProtocol(m_notesStoreHttpClient));
    m_notesStoreClient = new evernote::edam::NoteStoreClient(notesstoreiprot);
}

EvernoteConnection *EvernoteConnection::instance()
{
    if (!s_instance) {
        s_instance = new EvernoteConnection();
    }
    return s_instance;
}

EvernoteConnection::~EvernoteConnection()
{
    if (m_userstoreClient) {
        delete m_userstoreClient;
        m_userStoreHttpClient.reset();
    }
    if (m_notesStoreClient) {
        delete m_notesStoreClient;
        m_notesStoreHttpClient.reset();
    }
}

void EvernoteConnection::disconnectFromEvernote()
{
    if (!isConnected()) {
        qWarning() << "Not connected. Can't disconnect.";
        return;
    }

    foreach (EvernoteJob *job, m_jobQueue) {
        job->emitJobDone(EvernoteConnection::ErrorCodeConnectionLost, "Disconnected from Evernote");
        job->deleteLater();
    }
    m_jobQueue.clear();

    m_errorMessage.clear();
    emit errorChanged();

    try {
        m_notesStoreHttpClient->close();
        m_userStoreHttpClient->close();
    } catch (...) {}
    emit isConnectedChanged();
}

QString EvernoteConnection::hostname() const
{
    return m_hostname;
}

void EvernoteConnection::setHostname(const QString &hostname)
{
    if (m_hostname != hostname) {
        m_hostname = hostname;
        emit hostnameChanged();
    }
}

QString EvernoteConnection::token() const
{
    return m_token;
}

void EvernoteConnection::setToken(const QString &token)
{
    if (m_token != token) {
        m_token = token;
        emit tokenChanged();
    }
}

void EvernoteConnection::connectToEvernote()
{
    if (isConnected()) {
        qWarning() << "Already connected.";
        return;
    }

    m_errorMessage.clear();
    emit errorChanged();

    if (m_token.isEmpty()) {
        qWarning() << "Can't connect to Evernote. No token set.";
        return;
    }
    if (m_hostname.isEmpty()) {
        qWarning() << "Can't connect to Evernote. No hostname set.";
    }
    qDebug() << "******* Connecting *******";
    qDebug() << "hostname:" << m_hostname;
//    qDebug() << "token:" << m_token;

    setupUserStore();
    bool ok = connectUserStore();
    if (!ok) {
        qWarning() << "Error connecting User Store. Cannot continue.";
        return;
    }
    setupNotesStore();
    ok = connectNotesStore();

    if (!ok) {
        qWarning() << "Error connecting Notes Store. Cannot continue.";
        return;
    }

    qDebug() << "Connected!";
    emit isConnectedChanged();

}

bool EvernoteConnection::connectUserStore()
{
    if (m_userStoreHttpClient->isOpen()) {
        m_userStoreHttpClient->close();
    }

    try {
        m_userStoreHttpClient->open();
        qDebug() << "UserStoreClient socket opened.";
    } catch (const TTransportException & e) {
        qWarning() << "Failed to open connection:" <<  e.what() << e.getType();
        m_errorMessage = gettext("Offline mode");
        emit errorChanged();
        return false;
    } catch (const TException & e) {
        qWarning() << "Generic Thrift exception when opening the connection:" << e.what();
        m_errorMessage = gettext("Unknown error connecting to Evernote.");
        emit errorChanged();
        return false;
    }

    try {
        evernote::edam::UserStoreConstants constants;
        bool versionOk = m_userstoreClient->checkVersion(EDAM_CLIENT_NAME.toStdString(),
                                                                      constants.EDAM_VERSION_MAJOR,
                                                                      constants.EDAM_VERSION_MINOR);

        if (!versionOk) {
            qWarning() << "Server version mismatch! This application should be updated!";
            m_errorMessage = QString(gettext("Error connecting to Evernote: Server version does not match app version. Please update the application."));
            emit errorChanged();
            return false;
        }
    } catch (const evernote::edam::EDAMUserException e) {
        qWarning() << "Error fetching notestore url (EDAMUserException):" << e.what() << e.errorCode;
        m_errorMessage = QString(gettext("Error connecting to Evernote: Error code %1")).arg(e.errorCode);
        emit errorChanged();
        return false;
    } catch (const evernote::edam::EDAMSystemException e) {
        qWarning() << "Error fetching notestore url (EDAMSystemException):" << e.what() << e.errorCode;
        m_errorMessage = QString(gettext("Error connecting to Evernote: Error code %1")).arg(e.errorCode);
        emit errorChanged();
        return false;
    } catch (const TTransportException & e) {
        qWarning() << "Failed to fetch server version:" <<  e.what();
        m_errorMessage = QString(gettext("Error connecting to Evernote: Cannot download version information from server."));
        emit errorChanged();
        return false;
    } catch (const TException & e) {
        qWarning() << "Generic Thrift exception when fetching server version:" << e.what();
        m_errorMessage = QString(gettext("Unknown error connecting to Evernote"));
        emit errorChanged();
        return false;
    }

    try {
        std::string notesStoreUrl;
        qDebug() << "getting ntoe store url with token" << m_token;
        m_userstoreClient->getNoteStoreUrl(notesStoreUrl, m_token.toStdString());

        m_notesStorePath = QUrl(QString::fromStdString(notesStoreUrl)).path();

        if (m_notesStorePath.isEmpty()) {
            qWarning() << "Failed to fetch notesstore path from server. Fetching notes will not work.";
            m_errorMessage = QString(gettext("Error connecting to Evernote: Cannot download server information."));
            emit errorChanged();
            return false;
        }
    } catch (const TTransportException & e) {
        qWarning() << "Failed to fetch notestore path:" <<  e.what();
        m_errorMessage = QString(gettext("Error connecting to Evernote: Connection failure when downloading server information."));
        emit errorChanged();
        return false;
    } catch (const TException & e) {
        qWarning() << "Generic Thrift exception when fetching notestore path:" << e.what();
        m_errorMessage = gettext("Unknown error connecting to Evernote");
        emit errorChanged();
        return false;
    }

    return true;
}

bool EvernoteConnection::connectNotesStore()
{
    if (m_notesStoreHttpClient->isOpen()) {
        m_notesStoreHttpClient->close();
    }

    try {
        m_notesStoreHttpClient->open();
        qDebug() << "NotesStoreClient socket opened." << m_notesStoreHttpClient->isOpen();
        return true;

    } catch (const TTransportException & e) {
        qWarning() << "Failed to open connection:" <<  e.what();
        m_errorMessage = QString(gettext("Error connecting to Evernote: Connection failure"));
        emit errorChanged();
    } catch (const TException & e) {
        qWarning() << "Generic Thrift exception when opening the NotesStore connection:" << e.what();
        m_errorMessage = QString(gettext("Unknown Error connecting to Evernote"));
        emit errorChanged();
    }
    return false;
}

EvernoteJob* EvernoteConnection::findDuplicate(EvernoteJob *job)
{
    foreach (EvernoteJob *queuedJob, m_jobQueue) {
        // explicitly use custom operator==()
        if (job->operator ==(queuedJob)) {
            return queuedJob;
        }
    }
    return nullptr;
}

void EvernoteConnection::enqueue(EvernoteJob *job, JobPriority priority)
{
    if (!isConnected()) {
        qWarning() << "Not connected to evernote. Can't enqueue job.";
        job->emitJobDone(ErrorCodeConnectionLost, gettext("Disconnected from Evernote."));
        job->deleteLater();
        return;
    }
    EvernoteJob *duplicate = findDuplicate(job);
    if (duplicate) {
        job->attachToDuplicate(duplicate);
        connect(duplicate, &EvernoteJob::finished, job, &EvernoteJob::deleteLater);
        // reprioritze the repeated request
        if (priority == JobPriorityHigh) {
            m_jobQueue.prepend(m_jobQueue.takeAt(m_jobQueue.indexOf(duplicate)));
        }
    } else {
        connect(job, &EvernoteJob::finished, job, &EvernoteJob::deleteLater);
        connect(job, &EvernoteJob::finished, this, &EvernoteConnection::startNextJob);
        if (priority == JobPriorityHigh) {
            m_jobQueue.prepend(job);
        } else {
            m_jobQueue.append(job);
        }
        startJobQueue();
    }
}

bool EvernoteConnection::isConnected() const
{
    return m_userstoreClient != nullptr &&
            m_userStoreHttpClient->isOpen() &&
            m_notesStoreClient != nullptr &&
// The notesstoreHttpClient wont stay open for some reason, but still seems to work... ignore it...
//            m_notesStoreHttpClient->isOpen() &&
            !m_token.isEmpty();
}

QString EvernoteConnection::error() const
{
    return m_errorMessage;
}

void EvernoteConnection::startJobQueue()
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

void EvernoteConnection::startNextJob()
{
    m_currentJob = 0;
    startJobQueue();
}
