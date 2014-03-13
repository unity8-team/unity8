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

using namespace apache::thrift;
using namespace apache::thrift::protocol;
using namespace apache::thrift::transport;

EvernoteConnection* EvernoteConnection::s_instance = 0;

// FIXME: need to populate this string from the system
// The structure should be:
// application/version; platform/version; [ device/version ]
// E.g. "Evernote Windows/3.0.1; Windows/XP SP3"
QString EDAM_CLIENT_NAME = QStringLiteral("Reminders/0.1; Ubuntu/13.10");
QString EVERNOTE_HOST = QStringLiteral("sandbox.evernote.com");
QString EDAM_USER_STORE_PATH = QStringLiteral("/edam/user");
QString EDAM_NOTE_STORE_PATH = QStringLiteral("/edam/note");

EvernoteConnection::EvernoteConnection(QObject *parent) :
    QObject(parent),
    m_useSSL(true),
    m_currentJob(0)
{
    qRegisterMetaType<EvernoteConnection::ErrorCode>("EvernoteConnection::ErrorCode");
    setupUserStore();
    setupNotesStore();
}

bool EvernoteConnection::setupUserStore()
{
    bool versionOK = false;
    try {
        boost::shared_ptr<TSocket> socket;

        if (m_useSSL) {
            boost::shared_ptr<TSSLSocketFactory> sslSocketFactory(new TSSLSocketFactory());
            socket = sslSocketFactory->createSocket(EVERNOTE_HOST.toStdString(), 443);
            qDebug() << "created UserStore SSL socket";
        } else {
            // Create a non-secure socket
            socket = boost::shared_ptr<TSocket> (new TSocket(EVERNOTE_HOST.toStdString(), 80));
            qDebug() << "created insecure UserStore socket";
        }

        boost::shared_ptr<TBufferedTransport> bufferedTransport(new TBufferedTransport(socket));
        m_userStoreHttpClient = boost::shared_ptr<THttpClient>(new THttpClient(bufferedTransport,
                                                                            EVERNOTE_HOST.toStdString(),
                                                                            EDAM_USER_STORE_PATH.toStdString()));
        m_userStoreHttpClient->open();
        boost::shared_ptr<TProtocol> iprot(new TBinaryProtocol(m_userStoreHttpClient));
        m_userstoreClient = new evernote::edam::UserStoreClient(iprot);
        evernote::edam::UserStoreConstants constants;
        versionOK = m_userstoreClient->checkVersion(EDAM_CLIENT_NAME.toStdString(),
                                                                      constants.EDAM_VERSION_MAJOR,
                                                                      constants.EDAM_VERSION_MINOR);
        qDebug() << "UserStoreClient created. Version check:" << versionOK;

    } catch (const TTransportException & e) {
        qWarning() << "Failed to create Transport for UserStore:" <<  e.what();
    } catch (const TException & e) {
        qWarning() << "Generic Thrift exception in UserStore setup:" << e.what();
    }
    return versionOK;
}

bool EvernoteConnection::setupNotesStore()
{
    try {
        boost::shared_ptr<TSocket> socket;

        if (m_useSSL) {
            boost::shared_ptr<TSSLSocketFactory> sslSocketFactory(new TSSLSocketFactory());
            socket = sslSocketFactory->createSocket(EVERNOTE_HOST.toStdString(), 443);
            qDebug() << "created NotesStore SSL socket";
        } else {
            // Create a non-secure socket
            socket = boost::shared_ptr<TSocket> (new TSocket(EVERNOTE_HOST.toStdString(), 80));
            qDebug() << "created insecure NotesStore socket";
        }

        // setup UserStore
        boost::shared_ptr<TBufferedTransport> bufferedTransport(new TBufferedTransport(socket));
        m_notesStoreHttpClient = boost::shared_ptr<THttpClient>(new THttpClient(bufferedTransport,
                                                                            EVERNOTE_HOST.toStdString(),
                                                                            EDAM_NOTE_STORE_PATH.toStdString()));
        m_notesStoreHttpClient->open();
        boost::shared_ptr<TProtocol> iprot(new TBinaryProtocol(m_notesStoreHttpClient));

        // setup notesstore
        m_notesStoreClient = new evernote::edam::NoteStoreClient(iprot);

        qDebug() << "NoteStore client created.";

    } catch (const TTransportException & e) {
        qWarning() << "Failed to create Transport for NotesStore:" <<  e.what();
        return false;
    } catch (const TException & e) {
        qWarning() << "Generic Thrift exception in NotesStore setup:" << e.what();
        return false;
    }
    return true;
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
    delete m_notesStoreClient;
}

QString EvernoteConnection::token() const
{
    return m_token;
}

void EvernoteConnection::setToken(const QString &token)
{
    if (token != m_token) {
        m_token = token;
        emit tokenChanged();
    }
}

void EvernoteConnection::clearToken()
{
    if (!EvernoteConnection::instance()->token().isEmpty()) {
        setToken(QString());
    }
}

void EvernoteConnection::enqueue(EvernoteJob *job)
{
    connect(job, &EvernoteJob::finished, this, &EvernoteConnection::startNextJob);

    m_jobQueue.append(job);
    startJobQueue();
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
