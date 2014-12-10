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

#include "tag.h"
#include "note.h"

#include "notesstore.h"

#include <QStandardPaths>

Tag::Tag(const QString &guid, quint32 updateSequenceNumber, QObject *parent) :
    QObject(parent),
    m_updateSequenceNumber(updateSequenceNumber),
    m_guid(guid),
    m_infoFile(QStandardPaths::standardLocations(QStandardPaths::CacheLocation).first() + "/" + NotesStore::instance()->username() + "/tag-" + guid + ".info", QSettings::IniFormat)
{
    m_name = m_infoFile.value("name").toString();

    foreach (Note *note, NotesStore::instance()->notes()) {
        if (note->tagGuids().contains(m_guid)) {
            m_notesList.append(note->guid());
        }
    }
    connect(NotesStore::instance(), &NotesStore::noteAdded, this, &Tag::noteAdded);
    connect(NotesStore::instance(), &NotesStore::noteRemoved, this, &Tag::noteRemoved);
    connect(NotesStore::instance(), &NotesStore::noteChanged, this, &Tag::noteChanged);
}

Tag::~Tag()
{
}

QString Tag::guid() const
{
    return m_guid;
}

quint32 Tag::updateSequenceNumber() const
{
    return m_updateSequenceNumber;
}

void Tag::setUpdateSequenceNumber(quint32 updateSuequenceNumber)
{
    m_updateSequenceNumber = updateSuequenceNumber;
}

QString Tag::name() const
{
    return m_name;
}

void Tag::setName(const QString &name)
{
    if (m_name != name) {
        m_name = name;
        emit nameChanged();
    }
}

int Tag::noteCount() const
{
    return m_notesList.count();
}

Tag *Tag::clone()
{
    Tag *tag = new Tag(m_guid, m_updateSequenceNumber);
    tag->setName(m_name);
    return tag;
}

void Tag::noteAdded(const QString &noteGuid, const QString &notebookGuid)
{
    Q_UNUSED(notebookGuid)
    if (NotesStore::instance()->note(noteGuid)->tagGuids().contains(m_guid)) {
        m_notesList.append(noteGuid);
        emit noteCountChanged();
    }
}

void Tag::noteRemoved(const QString &noteGuid, const QString &notebookGuid)
{
    Q_UNUSED(notebookGuid)
    if (NotesStore::instance()->note(noteGuid)->tagGuids().contains(m_guid)) {
        m_notesList.removeAll(noteGuid);
        emit noteCountChanged();
    }
}

void Tag::noteChanged(const QString &noteGuid, const QString &notebookGuid)
{
    Q_UNUSED(notebookGuid)
    if (NotesStore::instance()->note(noteGuid)->tagGuids().contains(m_guid)) {
        if (!m_notesList.contains(noteGuid)) {
            m_notesList.append(noteGuid);
            emit noteCountChanged();
        }
    } else {
        if (m_notesList.contains(noteGuid)) {
            m_notesList.removeAll(noteGuid);
            emit noteCountChanged();
        }
    }
}

void Tag::syncToInfoFile()
{
    m_infoFile.setValue("name", m_name);
}
