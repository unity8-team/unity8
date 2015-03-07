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

#ifndef EVERNOTEJOB_H
#define EVERNOTEJOB_H

#include "evernoteconnection.h"

#include <QThread>

/* How to create a new Job type:
 * - Subclass EvernoteJob
 * - Implement startJob() in which you do the call to evernote.
 *   - No need to catch exceptions, EvernoteJob will deal with those.
 * - Define a jobDone() signal with the result parameters you need.
 *   - Keep the convention of jobDone(EvernoteConnection::ErrorCode errorCode, const QString &message [, ...])
 * - Emit jobDone() in your implementation of emitJobDone().
 *   - NOTE: emitJobDone() might be called with an error even before startJob() is triggered.
 * - reimplement attachToDuplciate(). In case there's already the exact same job in the queue
 *   your job won't be executed but you should instead forward the other's job results.
 *
 * Jobs can be enqueue()d in NotesStore.
 * The jobqueue will take care about starting them and deleting them.
 */
class EvernoteJob : public QThread
{
    Q_OBJECT
public:
    enum JobPriority {
        JobPriorityHigh,
        JobPriorityLow
    };

    explicit EvernoteJob(QObject *originatingObject = 0, JobPriority jobPriority = JobPriorityHigh);
    virtual ~EvernoteJob();

    JobPriority jobPriority() const;
    void setJobPriority(JobPriority priority = JobPriorityHigh);

    void run() final;

    virtual bool operator==(const EvernoteJob *other) const = 0;

    virtual void attachToDuplicate(const EvernoteJob *other) = 0;

    virtual QString toString() const;

    QObject* originatingObject() const;

signals:
    void connectionLost(const QString &errorMessage);

protected:
    virtual void resetConnection() = 0;
    virtual void startJob() = 0;
    virtual void emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage) = 0;

    QString token();

private:
    QString m_token;
    JobPriority m_jobPriority;
    QObject *m_originatingObject;

    friend class EvernoteConnection;
};

#endif // EVERNOTEJOB_H
