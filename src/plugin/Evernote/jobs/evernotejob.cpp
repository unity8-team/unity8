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
    connect(this, &EvernoteJob::finished, NotesStore::instance(), &NotesStore::startNextJob);
}

EvernoteJob::~EvernoteJob()
{
}

void EvernoteJob::run()
{
    if (m_token.isEmpty()) {
        qWarning() << "No token set. Cannot execute job.";
        emitJobDone(NotesStore::ErrorCodeUserException, QStringLiteral("No token set."));
        return;
    }

    try {
        startJob();

    } catch (const TTransportException & e) {

        // The connection broke down. libthrift + evernote servers seem to be quite flaky
        // so lets try to start the job once more.
        qWarning() << "Got a transport exception:" << e.what() << ". Trying to reestablish connection...";
        try {
            NotesStore::instance()->m_httpClient->close();
            NotesStore::instance()->m_httpClient->open();

            startJob();
        } catch (const TTransportException &e) {
            // Giving up... the connection seems to be down for real.
            qWarning() << "Cannot reestablish connection:" << e.what();
            emitJobDone(NotesStore::ErrorCodeConnectionLost, e.what());
        } catch (const evernote::edam::EDAMUserException &e) {
            emitJobDone(NotesStore::ErrorCodeUserException, e.what());
        } catch (const evernote::edam::EDAMSystemException &e) {
            emitJobDone(NotesStore::ErrorCodeSystemException, e.what());
        } catch (const evernote::edam::EDAMNotFoundException &e) {
            emitJobDone(NotesStore::ErrorCodeNotFoundExcpetion, e.what());
        }

    } catch (const evernote::edam::EDAMUserException &e) {
        emitJobDone(NotesStore::ErrorCodeUserException, e.what());
    } catch (const evernote::edam::EDAMSystemException &e) {
        emitJobDone(NotesStore::ErrorCodeSystemException, e.what());
    } catch (const evernote::edam::EDAMNotFoundException &e) {
        emitJobDone(NotesStore::ErrorCodeNotFoundExcpetion, e.what());
    }

    emitJobDone(NotesStore::ErrorCodeNoError, QString());
}

evernote::edam::NoteStoreClient *EvernoteJob::client()
{
    return NotesStore::instance()->m_client;
}

QString EvernoteJob::token()
{
    return m_token;
}
