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

#include "notebooks.h"
#include "notebook.h"

Notebooks::Notebooks(QObject *parent) :
    QAbstractListModel(parent)
{
    foreach (Notebook *notebook, NotesStore::instance()->notebooks()) {
        m_list.append(notebook->guid());
        connect(notebook, &Notebook::noteCountChanged, this, &Notebooks::noteCountChanged);
    }

    connect(NotesStore::instance(), &NotesStore::notebooksLoadingChanged, this, &Notebooks::loadingChanged);
    connect(NotesStore::instance(), &NotesStore::notebookAdded, this, &Notebooks::notebookAdded);
    connect(NotesStore::instance(), &NotesStore::notebookRemoved, this, &Notebooks::notebookRemoved);
    connect(NotesStore::instance(), &NotesStore::notebookGuidChanged, this, &Notebooks::notebookGuidChanged);
}

bool Notebooks::loading() const
{
    return NotesStore::instance()->notebooksLoading();
}

int Notebooks::count() const
{
    return rowCount();
}

QVariant Notebooks::data(const QModelIndex &index, int role) const
{
    Notebook *notebook = NotesStore::instance()->notebook(m_list.at(index.row()));
    switch(role) {
    case RoleGuid:
        return notebook->guid();
    case Qt::UserRole:
    case RoleName:
        return notebook->name();
    case RoleNoteCount:
        return notebook->noteCount();
    case RolePublished:
        return notebook->published();
    case RoleLastUpdated:
        return notebook->lastUpdated();
    case RoleLastUpdatedString:
        return notebook->lastUpdatedString();
    case RoleLoading:
        return notebook->loading();
    case RoleSynced:
        return notebook->synced();
    case RoleSyncError:
        return notebook->syncError();
    case RoleIsDefaultNotebook:
        return notebook->isDefaultNotebook();
    }
    return QVariant();
}

int Notebooks::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_list.count();
}

QHash<int, QByteArray> Notebooks::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles.insert(Qt::UserRole, "modelData");
    roles.insert(RoleGuid, "guid");
    roles.insert(RoleName, "name");
    roles.insert(RoleNoteCount, "noteCount");
    roles.insert(RolePublished, "published");
    roles.insert(RoleLastUpdated, "lastUpdated");
    roles.insert(RoleLastUpdatedString, "lastUpdatedString");
    roles.insert(RoleLoading, "loading");
    roles.insert(RoleSynced, "synced");
    roles.insert(RoleSyncError, "syncError");
    roles.insert(RoleIsDefaultNotebook, "isDefaultNotebook");
    return roles;
}

Notebook *Notebooks::notebook(int index) const
{
    if (index < 0 || index >= m_list.count()) {
        return nullptr;
    }
    return NotesStore::instance()->notebook(m_list.at(index));
}

void Notebooks::refresh()
{
    NotesStore::instance()->refreshNotebooks();
}

void Notebooks::notebookAdded(const QString &guid)
{
    Notebook *notebook = NotesStore::instance()->notebook(guid);
    connect(notebook, &Notebook::nameChanged, this, &Notebooks::nameChanged);
    connect(notebook, &Notebook::noteCountChanged, this, &Notebooks::noteCountChanged);
    connect(notebook, &Notebook::publishedChanged, this, &Notebooks::publishedChanged);
    connect(notebook, &Notebook::lastUpdatedChanged, this, &Notebooks::lastUpdatedChanged);
    connect(notebook, &Notebook::syncedChanged, this, &Notebooks::syncedChanged);
    connect(notebook, &Notebook::loadingChanged, this, &Notebooks::notebookLoadingChanged);
    connect(notebook, &Notebook::syncErrorChanged, this, &Notebooks::syncErrorChanged);
    connect(notebook, &Notebook::isDefaultNotebookChanged, this, &Notebooks::isDefaultNotebookChanged);

    beginInsertRows(QModelIndex(), m_list.count(), m_list.count());
    m_list.append(guid);
    endInsertRows();
    emit countChanged();
}

void Notebooks::notebookRemoved(const QString &guid)
{
    beginRemoveRows(QModelIndex(), m_list.indexOf(guid), m_list.indexOf(guid));
    m_list.removeAll(guid);
    endRemoveRows();
    emit countChanged();
}

void Notebooks::notebookGuidChanged(const QString &oldGuid, const QString &newGuid)
{
    int idx = m_list.indexOf(oldGuid);
    m_list.replace(idx, newGuid);
    emit dataChanged(index(idx), index(idx));
}

void Notebooks::isDefaultNotebookChanged()
{
    Notebook *notebook = static_cast<Notebook*>(sender());
    QModelIndex idx = index(m_list.indexOf((notebook->guid())));
    emit dataChanged(idx, idx, QVector<int>() << RoleIsDefaultNotebook);
}

void Notebooks::nameChanged()
{
    Notebook *notebook = static_cast<Notebook*>(sender());
    QModelIndex idx = index(m_list.indexOf(notebook->guid()));
    emit dataChanged(idx, idx, QVector<int>() << RoleName);
}

void Notebooks::noteCountChanged()
{
    Notebook *notebook = static_cast<Notebook*>(sender());
    QModelIndex idx = index(m_list.indexOf(notebook->guid()));
    emit dataChanged(idx, idx, QVector<int>() << RoleNoteCount);
}

void Notebooks::publishedChanged()
{
    Notebook *notebook = static_cast<Notebook*>(sender());
    QModelIndex idx = index(m_list.indexOf(notebook->guid()));
    emit dataChanged(idx, idx, QVector<int>() << RolePublished);
}

void Notebooks::lastUpdatedChanged()
{
    Notebook *notebook = static_cast<Notebook*>(sender());
    QModelIndex idx = index(m_list.indexOf(notebook->guid()));
    emit dataChanged(idx, idx, QVector<int>() << RoleLastUpdated);
}

void Notebooks::syncedChanged()
{
    Notebook *notebook = static_cast<Notebook*>(sender());
    QModelIndex idx = index(m_list.indexOf(notebook->guid()));
    emit dataChanged(idx, idx, QVector<int>() << RoleSynced);
}

void Notebooks::syncErrorChanged()
{
    Notebook *notebook = static_cast<Notebook*>(sender());
    QModelIndex idx = index(m_list.indexOf(notebook->guid()));
    emit dataChanged(idx, idx, QVector<int>() << RoleSyncError);
}

void Notebooks::notebookLoadingChanged()
{
    Notebook *notebook = static_cast<Notebook*>(sender());
    QModelIndex idx = index(m_list.indexOf(notebook->guid()));
    emit dataChanged(idx, idx, QVector<int>() << RoleLoading);
}
