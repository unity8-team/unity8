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

#ifndef CREATENOTEJOB_H
#define CREATENOTEJOB_H

#include "notesstorejob.h"

class CreateNoteJob : public NotesStoreJob
{
    Q_OBJECT
public:
    explicit CreateNoteJob(const QString &title, const QString &notebookGuid = QString(), const QString &content = QString(), QObject *parent = 0);

    virtual bool operator==(const EvernoteJob *other) const;
    virtual void attachToDuplicate(const EvernoteJob *other) override;

signals:
    void jobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, evernote::edam::Note note);

protected:
    void startJob();
    void emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage);

private:
    QString m_title;
    QString m_notebookGuid;
    QString m_content;

    evernote::edam::Note m_resultNote;
};

#endif // CREATENOTEJOB_H
