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

#include "note.h"

#include "notesstore.h"

Note::Note(const QString &guid, QObject *parent) :
    QObject(parent),
    m_guid(guid)
{
}

QString Note::guid() const
{
    return m_guid;
}

void Note::setGuid(const QString &guid)
{
    if (m_guid == guid) {
        m_guid = guid;
        emit guidChanged();
    }
}

QString Note::notebookGuid() const
{
    return m_notebookGuid;
}

void Note::setNotebookGuid(const QString &notebookGuid)
{
    if (m_notebookGuid != notebookGuid) {
        m_notebookGuid = notebookGuid;
        emit notebookGuidChanged();
    }
}

QString Note::title() const
{
    return m_title;
}

void Note::setTitle(const QString &title)
{
    if (m_title != title) {
        m_title = title;
        emit titleChanged();
    }
}

QString Note::content() const
{
    return m_content;
}

void Note::setContent(const QString &content)
{
    if (m_content != content) {
        m_content = content;
        emit contentChanged();
    }
}

void Note::save()
{
    NotesStore::instance()->saveNote(m_guid);
}

void Note::remove()
{
    NotesStore::instance()->deleteNote(m_guid);
}
