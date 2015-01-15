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
    m_loading(false),
    m_syncError(false)
{
    setGuid(guid);
    QSettings infoFile(m_infoFile, QSettings::IniFormat);
    m_name = infoFile.value("name").toString();
    m_lastSyncedSequenceNumber = infoFile.value("lastSyncedSequenceNumber", 0).toUInt();
    m_synced = m_lastSyncedSequenceNumber == m_updateSequenceNumber;

    foreach (Note *note, NotesStore::instance()->notes()) {
        if (note->tagGuids().contains(m_guid)) {
            m_notesList.append(note->guid());
        }
    }
    connect(NotesStore::instance(), &NotesStore::noteAdded, this, &Tag::noteAdded);
    connect(NotesStore::instance(), &NotesStore::noteRemoved, this, &Tag::noteRemoved);
    connect(NotesStore::instance(), &NotesStore::noteChanged, this, &Tag::noteChanged);
    connect(NotesStore::instance(), &NotesStore::noteGuidChanged, this, &Tag::noteGuidChanged);
}

Tag::~Tag()
{
}

QString Tag::guid() const
{
    return m_guid;
}

void Tag::setGuid(const QString &guid)
{
    bool syncToFile = false;
    if (!m_infoFile.isEmpty()) {
        QFile ifile(m_infoFile);
        ifile.remove();

        syncToFile = true;
    }

    m_guid = guid;
    m_infoFile = QStandardPaths::standardLocations(QStandardPaths::CacheLocation).first() + "/" + NotesStore::instance()->username() + "/tag-" + guid + ".info";

    if (syncToFile) {
        syncToInfoFile();
    }
    emit guidChanged();
}

quint32 Tag::updateSequenceNumber() const
{
    return m_updateSequenceNumber;
}

void Tag::setUpdateSequenceNumber(quint32 updateSequenceNumber)
{
    if (m_updateSequenceNumber != updateSequenceNumber) {
        m_updateSequenceNumber = updateSequenceNumber;

        m_synced = m_updateSequenceNumber == m_lastSyncedSequenceNumber;
        emit syncedChanged();
    }
}

quint32 Tag::lastSyncedSequenceNumber() const
{
    return m_lastSyncedSequenceNumber;
}

void Tag::setLastSyncedSequenceNumber(quint32 lastSyncedSequenceNumber)
{
    if (m_lastSyncedSequenceNumber != lastSyncedSequenceNumber) {
        m_lastSyncedSequenceNumber = lastSyncedSequenceNumber;

        m_synced = m_updateSequenceNumber == m_lastSyncedSequenceNumber;
        emit syncedChanged();
    }
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
    if (m_notesList.contains(noteGuid)) {
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

void Tag::noteGuidChanged(const QString &oldGuid, const QString &newGuid)
{
    int oldIndex = m_notesList.indexOf(oldGuid);
    if (oldIndex != -1) {
        m_notesList.replace(oldIndex, newGuid);
    }
}

void Tag::syncToInfoFile()
{
    QSettings infoFile(m_infoFile, QSettings::IniFormat);
    infoFile.setValue("name", m_name);
    infoFile.setValue("lastSyncedSequenceNumber", m_lastSyncedSequenceNumber);
}

void Tag::deleteInfoFile()
{
    QFile f(m_infoFile);
    if (f.exists()) {
        f.remove();
    }
}

bool Tag::loading() const
{
    return m_loading;
}

void Tag::setLoading(bool loading)
{
    if (m_loading != loading) {
        m_loading = loading;
        emit loadingChanged();
    }
}

bool Tag::synced() const
{
    return m_synced;
}

bool Tag::syncError() const
{
    return m_syncError;
}

void Tag::setSyncError(bool syncError)
{
    if (m_syncError != syncError) {
        m_syncError = syncError;
        emit syncErrorChanged();
    }
}
