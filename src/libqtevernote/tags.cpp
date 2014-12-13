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

#include "tags.h"
#include "tag.h"

#include <QDebug>

Tags::Tags(QObject *parent) :
    QAbstractListModel(parent)
{
    foreach (Tag *tag, NotesStore::instance()->tags()) {
        m_list.append(tag->guid());
        connect(tag, &Tag::noteCountChanged, this, &Tags::noteCountChanged);
    }

    connect(NotesStore::instance(), &NotesStore::tagsLoadingChanged, this, &Tags::loadingChanged);
    connect(NotesStore::instance(), &NotesStore::tagsErrorChanged, this, &Tags::errorChanged);
    connect(NotesStore::instance(), &NotesStore::tagAdded, this, &Tags::tagAdded);
    connect(NotesStore::instance(), &NotesStore::tagRemoved, this, &Tags::tagRemoved);
    connect(NotesStore::instance(), &NotesStore::tagGuidChanged, this, &Tags::tagGuidChanged);
}

bool Tags::loading() const
{
    return NotesStore::instance()->tagsLoading();
}

QString Tags::error() const
{
    return NotesStore::instance()->tagsError();
}

int Tags::count() const
{
    return rowCount();
}

QVariant Tags::data(const QModelIndex &index, int role) const
{
    Tag *tag = NotesStore::instance()->tag(m_list.at(index.row()));
    switch(role) {
    case RoleGuid:
        return tag->guid();
    case RoleName:
        return tag->name();
    case RoleNoteCount:
        return tag->noteCount();
    case RoleLoading:
        return tag->loading();
    case RoleSynced:
        return tag->synced();
    case RoleSyncError:
        return tag->syncError();
    }
    return QVariant();
}

int Tags::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_list.count();
}

QHash<int, QByteArray> Tags::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles.insert(RoleGuid, "guid");
    roles.insert(RoleName, "name");
    roles.insert(RoleNoteCount, "noteCount");
    roles.insert(RoleLoading, "loading");
    roles.insert(RoleSynced, "synced");
    roles.insert(RoleSyncError, "syncError");
    return roles;
}

Tag* Tags::tag(int index) const
{
    if (index < 0 || index >= m_list.count()) {
        return nullptr;
    }
    return NotesStore::instance()->tag(m_list.at(index));
}

void Tags::refresh()
{
    NotesStore::instance()->refreshTags();
}

void Tags::tagAdded(const QString &guid)
{
    Tag *tag = NotesStore::instance()->tag(guid);
    connect(tag, &Tag::nameChanged, this, &Tags::nameChanged);
    connect(tag, &Tag::noteCountChanged, this, &Tags::noteCountChanged);
    connect(tag, &Tag::loadingChanged, this, &Tags::tagLoadingChanged);
    connect(tag, &Tag::syncedChanged, this, &Tags::syncedChanged);
    connect(tag, &Tag::syncErrorChanged, this, &Tags::syncErrorChanged);

    beginInsertRows(QModelIndex(), m_list.count(), m_list.count());
    m_list.append(guid);
    endInsertRows();
    emit countChanged();
}

void Tags::tagRemoved(const QString &guid)
{
    beginRemoveRows(QModelIndex(), m_list.indexOf(guid), m_list.indexOf(guid));
    m_list.removeAll(guid);
    endRemoveRows();
    emit countChanged();
}

void Tags::tagGuidChanged(const QString &oldGuid, const QString &newGuid)
{
    int idx = m_list.indexOf(oldGuid);
    if (idx != -1) {
        m_list.replace(idx, newGuid);
        emit dataChanged(index(idx), index(idx), QVector<int>() << RoleGuid);
    }
}

void Tags::nameChanged()
{
    Tag *tag = static_cast<Tag*>(sender());
    QModelIndex idx = index(m_list.indexOf(tag->guid()));
    emit dataChanged(idx, idx, QVector<int>() << RoleName);
}

void Tags::noteCountChanged()
{
    Tag *tag= static_cast<Tag*>(sender());
    QModelIndex idx = index(m_list.indexOf(tag->guid()));
    emit dataChanged(idx, idx, QVector<int>() << RoleNoteCount);
}

void Tags::tagLoadingChanged()
{
    Tag *tag = static_cast<Tag*>(sender());
    QModelIndex idx = index(m_list.indexOf(tag->guid()));
    emit dataChanged(idx, idx, QVector<int>() << RoleLoading);
}

void Tags::syncedChanged()
{
    Tag *tag = static_cast<Tag*>(sender());
    QModelIndex idx = index(m_list.indexOf(tag->guid()));
    emit dataChanged(idx, idx, QVector<int>() << RoleSynced);
}

void Tags::syncErrorChanged()
{
    Tag *tag = static_cast<Tag*>(sender());
    QModelIndex idx = index(m_list.indexOf(tag->guid()));
    emit dataChanged(idx, idx, QVector<int>() << RoleSyncError);
}


