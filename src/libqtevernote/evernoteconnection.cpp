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
#include "logging.h"

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

#include <QUrl>
#include <QTime>

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

    m_reconnectTimer.setSingleShot(true);
    connect(&m_reconnectTimer, &QTimer::timeout, this, &EvernoteConnection::connectToEvernote);
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
        qCDebug(dcConnection) << "created UserStore SSL socket to host " << m_hostname;
    } else {
        // Create a non-secure socket
        socket = boost::shared_ptr<TSocket> (new TSocket(m_hostname.toStdString(), 80));
        qCDebug(dcConnection) << "created insecure UserStore socket to host " << m_hostname;
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
        qCDebug(dcConnection) << "created NotesStore SSL socket to host " << m_hostname;
    } else {
        // Create a non-secure socket
        socket = boost::shared_ptr<TSocket> (new TSocket(m_hostname.toStdString(), 80));
        qCDebug(dcConnection) << "created insecure NotesStore socket to host " << m_hostname;
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
    qCDebug(dcConnection) << "Disconnecting from Evernote.";

    m_errorMessage.clear();
    emit errorChanged();

    if (!isConnected()) {
        qCWarning(dcConnection()) << "Not connected. Can't disconnect.";
        return;
    }

    foreach (EvernoteJob *job, m_highPriorityJobQueue) {
        job->emitJobDone(EvernoteConnection::ErrorCodeConnectionLost, "Disconnected from Evernote");
        job->deleteLater();
    }
    m_highPriorityJobQueue.clear();

    foreach (EvernoteJob *job, m_mediumPriorityJobQueue) {
        job->emitJobDone(EvernoteConnection::ErrorCodeConnectionLost, "Disconnected from Evernote");
        job->deleteLater();
    }
    m_mediumPriorityJobQueue.clear();

    foreach (EvernoteJob *job, m_lowPriorityJobQueue) {
        job->emitJobDone(EvernoteConnection::ErrorCodeConnectionLost, "Disconnected from Evernote");
        job->deleteLater();
    }
    m_lowPriorityJobQueue.clear();

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
        qCWarning(dcConnection) << "Already connected.";
        return;
    }

    qCDebug(dcConnection) << "Connecting to Evernote:" << m_hostname;

    m_errorMessage.clear();
    emit errorChanged();

    if (m_token.isEmpty()) {
        qCWarning(dcConnection) << "Can't connect to Evernote. No token set.";
        return;
    }
    if (m_hostname.isEmpty()) {
        qCWarning(dcConnection) << "Can't connect to Evernote. No hostname set.";
    }

    setupUserStore();
    bool ok = connectUserStore();
    if (!ok) {
        qCWarning(dcConnection) << "Error connecting User Store. Cannot continue.";
        return;
    }
    setupNotesStore();
    ok = connectNotesStore();

    if (!ok) {
        qCWarning(dcConnection) << "Error connecting Notes Store. Cannot continue.";
        return;
    }

    qCDebug(dcConnection) << "Connected!";
    emit isConnectedChanged();

}

bool EvernoteConnection::connectUserStore()
{
    if (m_userStoreHttpClient->isOpen()) {
        m_userStoreHttpClient->close();
    }

    try {
        m_userStoreHttpClient->open();
        qCDebug(dcConnection) << "UserStoreClient socket opened.";
    } catch (const TTransportException & e) {
        qCWarning(dcConnection) << "Failed to open connection:" <<  e.what() << e.getType();
        m_errorMessage = gettext("Offline mode");
        emit errorChanged();
        return false;
    } catch (const TException & e) {
        qCWarning(dcConnection) << "Generic Thrift exception when opening the connection:" << e.what();
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
            qCWarning(dcConnection) << "Server version mismatch! This application should be updated!";
            m_errorMessage = QString(gettext("Error connecting to Evernote: Server version does not match app version. Please update the application."));
            emit errorChanged();
            return false;
        }
    } catch (const evernote::edam::EDAMUserException e) {
        qCWarning(dcConnection) << "Error fetching server version (EDAMUserException):" << e.what() << e.errorCode;
        m_errorMessage = QString(gettext("Error connecting to Evernote: Error code %1")).arg(e.errorCode);
        emit errorChanged();
        return false;
    } catch (const evernote::edam::EDAMSystemException e) {
        qCWarning(dcConnection) << "Error fetching server version: (EDAMSystemException):" << e.what() << e.errorCode;
        m_errorMessage = QString(gettext("Error connecting to Evernote: Error code %1")).arg(e.errorCode);
        emit errorChanged();
        return false;
    } catch (const TTransportException & e) {
        qCWarning(dcConnection) << "Failed to fetch server version:" <<  e.what();
        m_errorMessage = QString(gettext("Error connecting to Evernote: Cannot download version information from server."));
        emit errorChanged();
        return false;
    } catch (const TException & e) {
        qCWarning(dcConnection) << "Generic Thrift exception when fetching server version:" << e.what();
        m_errorMessage = QString(gettext("Unknown error connecting to Evernote"));
        emit errorChanged();
        return false;
    }

    try {
        std::string notesStoreUrl;
        qCDebug(dcConnection) << "getting ntoe store url with token" << m_token;
        m_userstoreClient->getNoteStoreUrl(notesStoreUrl, m_token.toStdString());

        m_notesStorePath = QUrl(QString::fromStdString(notesStoreUrl)).path();

        if (m_notesStorePath.isEmpty()) {
            qCWarning(dcConnection) << "Failed to fetch notesstore path from server. Fetching notes will not work.";
            m_errorMessage = QString(gettext("Error connecting to Evernote: Cannot download server information."));
            emit errorChanged();
            return false;
        }
    } catch (const evernote::edam::EDAMUserException &e) {
        qCWarning(dcConnection) << "EDAMUserException getting note store path:" << e.what() << "EDAM Error Code:" << e.errorCode;
        switch (e.errorCode) {
        case evernote::edam::EDAMErrorCode::AUTH_EXPIRED:
            m_errorMessage = gettext("Authentication for Evernote server expired. Please renew login information in the accounts settings.");
            break;
        default:
            m_errorMessage = QString(gettext("Unknown error connecting to Evernote: %1")).arg(e.errorCode);
            break;
        }
        emit errorChanged();
        return false;
    } catch (const evernote::edam::EDAMSystemException &e) {
        qCWarning(dcConnection) << "EDAMSystemException getting note store path:" << e.what() << e.errorCode;
        switch (e.errorCode) {
        case evernote::edam::EDAMErrorCode::RATE_LIMIT_REACHED:
            m_errorMessage = gettext("Error connecting to Evernote: Rate limit exceeded. Please try again later.");
            m_reconnectTimer.stop();
            m_reconnectTimer.start(e.rateLimitDuration * 1000);
            {
                QTime time = QTime::fromMSecsSinceStartOfDay(e.rateLimitDuration * 1000);
                qCDebug(dcConnection) << "Cannot connect. Rate limit exceeded. Reconnecting in" << time.toString("mm:ss");
            }
            break;
        default:
            m_errorMessage = gettext("Unknown error connecting to Evernote: %1");
            break;
        }
        emit errorChanged();
        return false;
    } catch (const TTransportException & e) {
        qCWarning(dcConnection) << "Failed to fetch notestore path:" <<  e.what();
        m_errorMessage = QString(gettext("Error connecting to Evernote: Connection failure when downloading server information."));
        emit errorChanged();
        return false;
    } catch (const TException & e) {
        qCWarning(dcConnection) << "Generic Thrift exception when fetching notestore path:" << e.what();
        m_errorMessage = gettext("Unknown error connecting to Evernote.");
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
        qCDebug(dcConnection) << "NotesStoreClient socket opened." << m_notesStoreHttpClient->isOpen();
        return true;

    } catch (const TTransportException & e) {
        qCWarning(dcConnection) << "Failed to open connection:" <<  e.what();
        m_errorMessage = QString(gettext("Error connecting to Evernote: Connection failure"));
        emit errorChanged();
    } catch (const TException & e) {
        qCWarning(dcConnection) << "Generic Thrift exception when opening the NotesStore connection:" << e.what();
        m_errorMessage = QString(gettext("Unknown Error connecting to Evernote"));
        emit errorChanged();
    }
    return false;
}

void EvernoteConnection::attachDuplicate(EvernoteJob *original, EvernoteJob *duplicate)
{
    if (duplicate->originatingObject() && duplicate->originatingObject() != original->originatingObject()) {
        duplicate->attachToDuplicate(m_currentJob);
    }
    connect(original, &EvernoteJob::jobFinished, duplicate, &EvernoteJob::deleteLater);
}

EvernoteJob* EvernoteConnection::findExistingDuplicate(EvernoteJob *job)
{
    qCDebug(dcJobQueue) << "Length:"
                        << m_highPriorityJobQueue.count() + m_mediumPriorityJobQueue.count() + m_lowPriorityJobQueue.count()
                        << "(High:" << m_highPriorityJobQueue.count() << "Medium:" << m_mediumPriorityJobQueue.count() << "Low:" << m_lowPriorityJobQueue.count() << ")";

    foreach (EvernoteJob *queuedJob, m_highPriorityJobQueue) {
        // explicitly use custom operator==()
        if (job->operator ==(queuedJob)) {
            qCDebug(dcJobQueue) << "Found duplicate in high priority queue";
            return queuedJob;
        }
    }
    foreach (EvernoteJob *queuedJob, m_mediumPriorityJobQueue) {
        // explicitly use custom operator==()
        if (job->operator ==(queuedJob)) {
            qCDebug(dcJobQueue) << "Found duplicate in medium priority queue";
            return queuedJob;
        }
    }
    foreach (EvernoteJob *queuedJob, m_lowPriorityJobQueue) {
        // explicitly use custom operator==()
        if (job->operator ==(queuedJob)) {
            qCDebug(dcJobQueue) << "Found duplicate in low priority queue";
            return queuedJob;
        }
    }
    return nullptr;
}

void EvernoteConnection::enqueue(EvernoteJob *job)
{
    if (!isConnected()) {
        qCWarning(dcJobQueue) << "Not connected to evernote. Can't enqueue job.";
        job->emitJobDone(ErrorCodeConnectionLost, gettext("Disconnected from Evernote."));
        job->deleteLater();
        return;
    }
    if (m_currentJob && m_currentJob->operator ==(job)) {
        qCDebug(dcJobQueue) << "Duplicate of new job request already running:" << job->toString();
        if (m_currentJob->isFinished()) {
            qCWarning(dcJobQueue) << "Job seems to be stuck in a loop. Deleting it:" << job->toString();
            job->deleteLater();
        } else {
            attachDuplicate(m_currentJob, job);
        }
        return;
    }
    EvernoteJob *existingJob = findExistingDuplicate(job);
    if (existingJob) {
        qCDebug(dcJobQueue) << "Duplicate job already queued:" << job->toString();
        attachDuplicate(existingJob, job);
        // reprioritze the repeated request
        if (job->jobPriority() == EvernoteJob::JobPriorityHigh) {
            qCDebug(dcJobQueue) << "Reprioritising duplicate job in high priority queue:" << job->toString();
            existingJob->setJobPriority(job->jobPriority());
            if (m_highPriorityJobQueue.contains(existingJob)) {
                m_highPriorityJobQueue.prepend(m_highPriorityJobQueue.takeAt(m_highPriorityJobQueue.indexOf(existingJob)));
            } else if (m_mediumPriorityJobQueue.contains(existingJob)){
                m_highPriorityJobQueue.prepend(m_mediumPriorityJobQueue.takeAt(m_mediumPriorityJobQueue.indexOf(existingJob)));
            } else {
                m_highPriorityJobQueue.prepend(m_lowPriorityJobQueue.takeAt(m_lowPriorityJobQueue.indexOf(existingJob)));
            }
        } else if (job->jobPriority() == EvernoteJob::JobPriorityMedium){
            if (m_mediumPriorityJobQueue.contains(existingJob)) {
                qCDebug(dcJobQueue) << "Reprioritising duplicate job in medium priority queue:" << job->toString();
                m_mediumPriorityJobQueue.prepend(m_mediumPriorityJobQueue.takeAt(m_mediumPriorityJobQueue.indexOf(existingJob)));
            } else if (m_lowPriorityJobQueue.contains(existingJob)) {
                m_mediumPriorityJobQueue.prepend(m_lowPriorityJobQueue.takeAt(m_lowPriorityJobQueue.indexOf(existingJob)));
            }
        } else if (job->jobPriority() == EvernoteJob::JobPriorityLow) {
            if (m_lowPriorityJobQueue.contains(existingJob)) {
                qCDebug(dcJobQueue) << "Reprioritising duplicate job in low priority queue:" << job->toString();
                m_lowPriorityJobQueue.prepend(m_lowPriorityJobQueue.takeAt(m_lowPriorityJobQueue.indexOf(existingJob)));
            }
        }
    } else {
        connect(job, &EvernoteJob::jobFinished, job, &EvernoteJob::deleteLater);
        connect(job, &EvernoteJob::jobFinished, this, &EvernoteConnection::startNextJob);
        if (job->jobPriority() == EvernoteJob::JobPriorityHigh) {
            qCDebug(dcJobQueue) << "Adding high priority job request:" << job->toString();
            m_highPriorityJobQueue.prepend(job);
        } else if (job->jobPriority() == EvernoteJob::JobPriorityMedium){
            qCDebug(dcJobQueue) << "Adding medium priority job request:" << job->toString();
            m_mediumPriorityJobQueue.prepend(job);
        } else {
            qCDebug(dcJobQueue) << "Adding low priority job request:" << job->toString();
            m_lowPriorityJobQueue.prepend(job);
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
    if (m_currentJob) {
        return;
    }

    if (!m_highPriorityJobQueue.isEmpty()) {
        m_currentJob = m_highPriorityJobQueue.takeFirst();
    } else if (!m_mediumPriorityJobQueue.isEmpty()){
        m_currentJob = m_mediumPriorityJobQueue.takeFirst();
    } else if (!m_lowPriorityJobQueue.isEmpty()){
        m_currentJob = m_lowPriorityJobQueue.takeFirst();
    }

    if (!m_currentJob) {
        qCDebug(dcJobQueue) << "Queue empty. Nothing to do.";
        return;
    }

    qCDebug(dcJobQueue) << QString("Starting job (Priority: %1):").arg(m_currentJob->jobPriority()) << m_currentJob->toString();
    m_currentJob->start();
}

void EvernoteConnection::startNextJob()
{
    qCDebug(dcJobQueue) << "Job done:" << m_currentJob->toString();
    m_currentJob = 0;
    startJobQueue();
}
