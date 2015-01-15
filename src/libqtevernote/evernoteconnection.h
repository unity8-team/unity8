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

#ifndef EVERNOTECONNECTION_H
#define EVERNOTECONNECTION_H

#include <boost/shared_ptr.hpp>

// Thrift
#include <transport/THttpClient.h>

#include <QObject>

namespace evernote {
namespace edam {
class NoteStoreClient;
class UserStoreClient;
}
}

using namespace apache::thrift::transport;

class EvernoteJob;

class EvernoteConnection : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString hostname READ hostname WRITE setHostname NOTIFY hostnameChanged)
    Q_PROPERTY(QString token READ token WRITE setToken NOTIFY tokenChanged)
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY isConnectedChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

    friend class NotesStoreJob;
    friend class UserStoreJob;

public:
    enum ErrorCode {
        ErrorCodeNoError,
        ErrorCodeUserException,
        ErrorCodeSystemException,
        ErrorCodeNotFoundExcpetion,
        ErrorCodeConnectionLost,
        ErrorCodeAuthExpired,
        ErrorCodeRateLimitExceeded,
        ErrorCodeLimitExceeded,
        ErrorCodeQutaExceeded
    };

    enum JobPriority {
        JobPriorityHigh,
        JobPriorityLow
    };

    static EvernoteConnection* instance();
    ~EvernoteConnection();

    QString hostname() const;
    void setHostname(const QString &hostname);

    QString token() const;
    void setToken(const QString &token);

    void enqueue(EvernoteJob *job, JobPriority priority = JobPriorityHigh);

    bool isConnected() const;

    QString error() const;

public slots:
    void connectToEvernote();
    void disconnectFromEvernote();

signals:
    void hostnameChanged();
    void tokenChanged();
    void isConnectedChanged();
    void errorChanged();

private slots:

    void startJobQueue();
    void startNextJob();

private:
    explicit EvernoteConnection(QObject *parent = 0);
    static EvernoteConnection *s_instance;

    void setupEvernoteConnection();
    void setupUserStore();
    void setupNotesStore();
    bool connectUserStore();
    bool connectNotesStore();

    EvernoteJob* findDuplicate(EvernoteJob *job);

    bool m_useSSL;
    bool m_isConnected;
    QString m_notesStorePath;
    QString m_hostname;
    QString m_token;
    QString m_errorMessage;

    // There must be only one job running at a time
    // Do not start jobs other than with startJobQueue()
    QList<EvernoteJob*> m_jobQueue;
    EvernoteJob *m_currentJob;

    // Those need to be mutexed
    evernote::edam::NoteStoreClient *m_notesStoreClient;
    boost::shared_ptr<THttpClient> m_notesStoreHttpClient;

    evernote::edam::UserStoreClient *m_userstoreClient;
    boost::shared_ptr<THttpClient> m_userStoreHttpClient;
};

#endif // EVERNOTECONNECTION_H
