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

#include "fetchnotejob.h"

FetchNoteJob::FetchNoteJob(const QString &guid, QObject *parent) :
    NotesStoreJob(parent),
    m_guid(guid)
{
}

void FetchNoteJob::startJob()
{
    client()->getNote(m_result, token().toStdString(), m_guid.toStdString(), true, true, false, false);
}

void FetchNoteJob::emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage)
{
    emit resultReady(errorCode, errorMessage, m_result);
}
