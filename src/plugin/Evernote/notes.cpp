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
    QSortFilterProxyModel(parent),
    m_onlyReminders(false)
{
    setSourceModel(NotesStore::instance());
    setSortRole(NotesStore::RoleCreated);
    sort(0, Qt::DescendingOrder);
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
        invalidateFilter();
    }
}

bool Notes::onlyReminders() const
{
    return m_onlyReminders;
}

void Notes::setOnlyReminders(bool onlyReminders)
{
    if (m_onlyReminders != onlyReminders) {
        m_onlyReminders = onlyReminders;
        emit onlyRemindersChanged();
        invalidateFilter();
    }
}

bool Notes::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    QModelIndex sourceIndex = sourceModel()->index(sourceRow, 0, sourceParent);
    if (!m_filterNotebookGuid.isEmpty()) {
        if (sourceModel()->data(sourceIndex, NotesStore::RoleNotebookGuid).toString() != m_filterNotebookGuid) {
            return false;
        }
    }
    if (m_onlyReminders) {
        if (!sourceModel()->data(sourceIndex, NotesStore::RoleReminder).toBool()) {
            return false;
        }
    }
    return true;
}
