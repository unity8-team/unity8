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

// Evernote SDK
#include <Errors_types.h>

#include <libintl.h>

#include <QDebug>

using namespace apache::thrift;
using namespace apache::thrift::protocol;
using namespace apache::thrift::transport;

EvernoteJob::EvernoteJob(QObject *parent) :
    QThread(parent),
    m_token(EvernoteConnection::instance()->token())
{
}

EvernoteJob::~EvernoteJob()
{
}

void EvernoteJob::run()
{
    if (!EvernoteConnection::instance()->isConnected()) {
        qWarning() << "EvernoteConnection is not connected. (" << this->metaObject()->className() << ")";
        emitJobDone(EvernoteConnection::ErrorCodeUserException, QStringLiteral("Not connected."));
        return;
    }

    bool done = false;
    int retry = 0;
    int maxTries = 2;
    while (!done && retry < maxTries) {
        try {
            if (retry > 0) {
                // If this is not the first try, reset the connection first.
                qWarning() << "Resetting connection...";
                resetConnection();
            }
            retry++;

            startJob();
            emitJobDone(EvernoteConnection::ErrorCodeNoError, QString());
            done = true;
        } catch (const TTransportException & e) {
            qWarning() << "Got a transport exception:" << e.what();
            if (retry >= maxTries)
                emitJobDone(EvernoteConnection::ErrorCodeConnectionLost, e.what());
        } catch (const TApplicationException &e) {
            qWarning() << "Cannot reestablish connection:" << e.what();
            if (retry >= maxTries)
                emitJobDone(EvernoteConnection::ErrorCodeConnectionLost, e.what());
        } catch (const evernote::edam::EDAMUserException &e) {
            qWarning() << "EDAMUserException" << e.what();
            if (retry >= maxTries)
                emitJobDone(EvernoteConnection::ErrorCodeUserException, e.what());
        } catch (const evernote::edam::EDAMSystemException &e) {
            qWarning() << "EDAMSystemException" << e.what() << e.errorCode << QString::fromStdString(e.message);
            if (retry >= maxTries) {
                QString message;
                EvernoteConnection::ErrorCode errorCode;
                switch (e.errorCode) {
                case evernote::edam::EDAMErrorCode::AUTH_EXPIRED:
                    message = gettext("Authentication expired.");
                    errorCode = EvernoteConnection::ErrorCodeAuthExpired;
                    break;
                case evernote::edam::EDAMErrorCode::LIMIT_REACHED:
                    message = gettext("Limit exceeded.");
                    errorCode = EvernoteConnection::ErrorCodeLimitExceeded;
                    break;
                case evernote::edam::EDAMErrorCode::RATE_LIMIT_REACHED:
                    message = gettext("Rate limit exceeded.");
                    errorCode = EvernoteConnection::ErrorCodeRateLimitExceeded;
                    break;
                case evernote::edam::EDAMErrorCode::QUOTA_REACHED:
                    message = gettext("Quota exceeded.");
                    errorCode = EvernoteConnection::ErrorCodeQutaExceeded;
                    break;
                default:
                    message = e.what();
                    errorCode = EvernoteConnection::ErrorCodeSystemException;
                }
                emitJobDone(errorCode, message);
            }
        } catch (const evernote::edam::EDAMNotFoundException &e) {
            qWarning() << "EDAMNotFoundException" << e.what();
            if (retry >= maxTries)
                emitJobDone(EvernoteConnection::ErrorCodeNotFoundExcpetion, e.what());
        }
    }
}

QString EvernoteJob::token()
{
    return m_token;
}
