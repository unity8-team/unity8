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

#include "notes.h"
#include "note.h"

#include <QDebug>

Notes::Notes(QObject *parent) :
    QAbstractListModel(parent)
{
    connect(NotesStore::instance(), &NotesStore::noteAdded, this, &Notes::noteAdded);
    connect(NotesStore::instance(), &NotesStore::noteRemoved, this, &Notes::noteRemoved);
    connect(NotesStore::instance(), &NotesStore::noteChanged, this, &Notes::noteChanged);
}

QVariant Notes::data(const QModelIndex &index, int role) const
{
    Note *note = NotesStore::instance()->note(m_list.at(index.row()));
    switch(role) {
    case RoleGuid:
        return note->guid();
    case RoleTitle:
        return note->title();
    }

    return QVariant();
}

int Notes::rowCount(const QModelIndex &parent) const
{
    return m_list.count();
}

QHash<int, QByteArray> Notes::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles.insert(RoleGuid, "guid");
    roles.insert(RoleTitle, "title");
    return roles;
}

QString Notes::filterNotebookGuid() const
{
    return m_filterNotebookGuid;
}

void Notes::setFilterNotebookGuid(const QString &notebookGuid)
{
    if (m_filterNotebookGuid != notebookGuid) {
        m_filterNotebookGuid = notebookGuid;
        emit filterNotebookGuidChanged();
    }
}

Note* Notes::note(const QString &guid)
{
    NotesStore::instance()->refreshNoteContent(guid);
    return NotesStore::instance()->note(guid);
}

void Notes::componentComplete()
{
    foreach (Note *note, NotesStore::instance()->notes()) {
        if (m_filterNotebookGuid.isEmpty() || note->notebookGuid() == m_filterNotebookGuid) {
            m_list.append(note->guid());
        }
    }
    beginInsertRows(QModelIndex(), 0, m_list.count() - 1);
    endInsertRows();
    refresh();
}

void Notes::refresh()
{
    NotesStore::instance()->refreshNotes(m_filterNotebookGuid);
}

void Notes::noteAdded(const QString &guid)
{
    beginInsertRows(QModelIndex(), m_list.count(), m_list.count());
    m_list.append(guid);
    endInsertRows();
}

void Notes::noteChanged(const QString &guid)
{
    int row = m_list.indexOf(guid);
    if (row >= 0) {
        emit dataChanged(index(row), index(row));
    }
}

void Notes::noteRemoved(const QString &guid)
{
    int index = m_list.indexOf(guid);
    if (index >= 0) {
        beginRemoveRows(QModelIndex(), index, index);
        m_list.removeAt(index);
        endRemoveRows();
    }
}
