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

#include "notesstorejob.h"

#include "evernoteconnection.h"

NotesStoreJob::NotesStoreJob(QObject *parent) :
    EvernoteJob(parent)
{
}

void NotesStoreJob::resetConnection()
{
    if (EvernoteConnection::instance()->m_notesStoreHttpClient->isOpen()) {
        EvernoteConnection::instance()->m_notesStoreHttpClient->close();
    }
    EvernoteConnection::instance()->m_notesStoreHttpClient->open();
}

evernote::edam::NoteStoreClient *NotesStoreJob::client() const
{
    return EvernoteConnection::instance()->m_notesStoreClient;
}
