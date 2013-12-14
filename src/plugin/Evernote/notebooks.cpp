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

    connect(NotesStore::instance(), SIGNAL(notebookAdded(const QString &)), SLOT(notebookAdded(const QString &)));
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
    }
    return QVariant();
}

int Notebooks::rowCount(const QModelIndex &parent) const
{
    return m_list.count();
}

QHash<int, QByteArray> Notebooks::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles.insert(RoleGuid, "guid");
    roles.insert(RoleName, "name");
    roles.insert(RoleNoteCount, "noteCount");
    roles.insert(RolePublished, "publised");
    return roles;
}

void Notebooks::refresh()
{
    NotesStore::instance()->refreshNotebooks();
}

void Notebooks::notebookAdded(const QString &guid)
{
    Notebook *notebook = NotesStore::instance()->notebook(guid);
    connect(notebook, &Notebook::noteCountChanged, this, &Notebooks::noteCountChanged);

    beginInsertRows(QModelIndex(), m_list.count(), m_list.count());
    m_list.append(guid);
    endInsertRows();
}

void Notebooks::noteCountChanged()
{
    Notebook *notebook = static_cast<Notebook*>(sender());
    QModelIndex idx = index(m_list.indexOf(notebook->guid()));
    emit dataChanged(idx, idx, QVector<int>() << RoleNoteCount);
}
