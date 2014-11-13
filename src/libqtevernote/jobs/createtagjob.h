/*
 * Copyright: 2014 Canonical, Ltd
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

#ifndef CREATETAGJOB_H
#define CREATETAGJOB_H

#include "notesstorejob.h"

class CreateTagJob : public NotesStoreJob
{
    Q_OBJECT
public:
    explicit CreateTagJob(const QString &name, QObject *parent = 0);

    virtual void startJob() override;

    virtual bool operator==(const EvernoteJob *other) const override;
    virtual void attachToDuplicate(const EvernoteJob *other) override;

signals:
    void jobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Tag &result);

private slots:
    void emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage);

private:
    QString m_name;

    evernote::edam::Tag m_result;
};

#endif // CREATENOTEBOOKJOB_H
