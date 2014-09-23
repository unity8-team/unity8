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

#include <QDebug>

Notebooks::Notebooks(QObject *parent) :
    QAbstractListModel(parent)
{
    foreach (Notebook *notebook, NotesStore::instance()->notebooks()) {
        m_list.append(notebook->guid());
        connect(notebook, &Notebook::noteCountChanged, this, &Notebooks::noteCountChanged);
    }

    connect(NotesStore::instance(), &NotesStore::notebooksLoadingChanged, this, &Notebooks::loadingChanged);
    connect(NotesStore::instance(), &NotesStore::notebooksErrorChanged, this, &Notebooks::errorChanged);
    connect(NotesStore::instance(), SIGNAL(notebookAdded(const QString &)), SLOT(notebookAdded(const QString &)));
    connect(NotesStore::instance(), SIGNAL(notebookRemoved(const QString &)), SLOT(notebookRemoved(const QString &)));
}

bool Notebooks::loading() const
{
    return NotesStore::instance()->notebooksLoading();
}

QString Notebooks::error() const
{
    return NotesStore::instance()->notebooksError();
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
    roles.insert(RoleGuid, "guid");
    roles.insert(RoleName, "name");
    roles.insert(RoleNoteCount, "noteCount");
    roles.insert(RolePublished, "published");
    roles.insert(RoleLastUpdated, "lastUpdated");
    roles.insert(RoleLastUpdatedString, "lastUpdatedString");
    return roles;
}

Notebook *Notebooks::notebook(int index)
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
