/*
 * Copyright: 2013 Canonical, Ltd
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
 */

#include "evernotejob.h"
#include "evernoteconnection.h"

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
    m_token(EvernoteConnection::instance()->token())
{
    connect(this, &EvernoteJob::finished, this, &EvernoteJob::deleteLater);
}

EvernoteJob::~EvernoteJob()
{
}

void EvernoteJob::run()
{
    if (EvernoteConnection::instance()->isConfigured()) {
        qWarning() << "EvernoteConnection not set up completely. You need to set a hostname and a token. Cannot execute job. (" << this->metaObject()->className() << ")";
        emitJobDone(EvernoteConnection::ErrorCodeUserException, QStringLiteral("Token or hostname not set."));
        return;
    }

    try {
        startJob();
        emitJobDone(EvernoteConnection::ErrorCodeNoError, QString());
    } catch (const TTransportException & e) {

        // The connection broke down. libthrift + evernote servers seem to be quite flaky
        // so lets try to start the job once more.
        qWarning() << "Got a transport exception:" << e.what() << ". Trying to reestablish connection...";
        try {
            resetConnection();
            startJob();
            emitJobDone(EvernoteConnection::ErrorCodeNoError, QString());
        } catch (const TTransportException &e) {
            // Giving up... the connection seems to be down for real.
            qWarning() << "Cannot reestablish connection:" << e.what();
            emitJobDone(EvernoteConnection::ErrorCodeConnectionLost, e.what());
        } catch (const TApplicationException &e) {
            qWarning() << "Cannot reestablish connection:" << e.what();
            emitJobDone(EvernoteConnection::ErrorCodeConnectionLost, e.what());
        } catch (const evernote::edam::EDAMUserException &e) {
            qWarning() << "EDAMUserException" << e.what();
            emitJobDone(EvernoteConnection::ErrorCodeUserException, e.what());
        } catch (const evernote::edam::EDAMSystemException &e) {
            qWarning() << "EDAMSystemException" << e.what();
            emitJobDone(EvernoteConnection::ErrorCodeSystemException, e.what());
        } catch (const evernote::edam::EDAMNotFoundException &e) {
            qWarning() << "EDAMNotFoundException" << e.what();
            emitJobDone(EvernoteConnection::ErrorCodeNotFoundExcpetion, e.what());
        }


    } catch (const evernote::edam::EDAMUserException &e) {
        qWarning() << "EDAMUserException" << e.what() << e.errorCode;
        emitJobDone(EvernoteConnection::ErrorCodeUserException, e.what());
    } catch (const evernote::edam::EDAMSystemException &e) {
        qWarning() << "EDAMSystemException" << e.what();
        emitJobDone(EvernoteConnection::ErrorCodeSystemException, e.what());
    } catch (const evernote::edam::EDAMNotFoundException &e) {
        qWarning() << "EDAMNotFoundException" << e.what();
        emitJobDone(EvernoteConnection::ErrorCodeNotFoundExcpetion, e.what());
    }
}

QString EvernoteJob::token()
{
    return m_token;
}
