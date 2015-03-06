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

#include "notes.h"
#include "note.h"

#include <QDebug>

Notes::Notes(QObject *parent) :
    QSortFilterProxyModel(parent),
    m_onlyReminders(false),
    m_onlySearchResults(false),
    m_showDeleted(false),
    m_sortOrder(SortOrderDateUpdatedNewest)
{
    connect(NotesStore::instance(), &NotesStore::loadingChanged, this, &Notes::loadingChanged);
    connect(NotesStore::instance(), &NotesStore::errorChanged, this, &Notes::errorChanged);
    connect(NotesStore::instance(), &NotesStore::countChanged, this, &Notes::countChanged);
    setSourceModel(NotesStore::instance());
    setSortRole(NotesStore::RoleUpdated);
    sort(0, Qt::DescendingOrder);
    invalidateFilter();
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
        emit countChanged();
    }
}

QString Notes::filterTagGuid() const
{
    return m_filterTagGuid;
}

void Notes::setFilterTagGuid(const QString &tagGuid)
{
    if (m_filterTagGuid != tagGuid) {
        m_filterTagGuid = tagGuid;
        emit filterTagGuidChanged();
        invalidateFilter();
        emit countChanged();
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
        if (onlyReminders) {
            setSortRole(NotesStore::RoleReminderSorting);
            sort(0, Qt::AscendingOrder);
        } else {
            setSortRole(NotesStore::RoleUpdated);
            sort(0, Qt::DescendingOrder);
        }

        invalidateFilter();
        emit countChanged();
    }
}

bool Notes::onlySearchResults() const
{
    return m_onlySearchResults;
}

void Notes::setOnlySearchResults(bool onlySearchResults)
{
    if (m_onlySearchResults != onlySearchResults) {
        m_onlySearchResults = onlySearchResults;
        emit onlySearchResultsChanged();
        invalidateFilter();
        emit countChanged();
    }
}

bool Notes::showDeleted() const
{
    return m_showDeleted;
}

void Notes::setShowDeleted(bool showDeleted)
{
    if (m_showDeleted != showDeleted) {
        m_showDeleted = showDeleted;
        emit showDeletedChanged();
        invalidateFilter();
        emit countChanged();
    }
}

bool Notes::loading() const
{
    return NotesStore::instance()->loading();
}

QString Notes::error() const
{
    return NotesStore::instance()->error();
}

int Notes::count() const
{
    return rowCount();
}

Note *Notes::note(const QString &guid)
{
    return NotesStore::instance()->note(guid);
}

int Notes::sectionCount(const QString &sectionRole, const QString &section)
{
    NotesStore::Role role = (NotesStore::Role)roleNames().key(sectionRole.toLatin1());
    int count = 0;
    for (int i = 0; i < rowCount(); i++) {
        QString itemSection;
        itemSection = data(index(i, 0), role).toString();
        if (section == itemSection) {
            count++;
        }
    }
    return count;
}

Notes::SortOrder Notes::sortOrder() const
{
    return m_sortOrder;
}

void Notes::setSortOrder(Notes::SortOrder sortOrder)
{
    if (m_sortOrder != sortOrder) {
        emit layoutAboutToBeChanged();
        switch (sortOrder) {
        case SortOrderDateCreatedNewest:
            setSortRole(NotesStore::RoleCreated);
            sort(0, Qt::DescendingOrder);
            break;
        case SortOrderDateCreatedOldest:
            setSortRole(NotesStore::RoleCreated);
            sort(0, Qt::AscendingOrder);
            break;
        case SortOrderDateUpdatedNewest:
            setSortRole(NotesStore::RoleUpdated);
            sort(0, Qt::DescendingOrder);
            break;
        case SortOrderDateUpdatedOldest:
            setSortRole(NotesStore::RoleUpdated);
            sort(0, Qt::AscendingOrder);
            break;
        case SortOrderTitleAscending:
            setSortRole(NotesStore::RoleTitle);
            sort(0, Qt::AscendingOrder);
            break;
        case SortOrderTitleDescending:
            setSortRole(NotesStore::RoleTitle);
            sort(0, Qt::DescendingOrder);
            break;
        }
        m_sortOrder = sortOrder;
        emit sortOrderChanged();
        emit layoutChanged();
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
    if (!m_filterTagGuid.isEmpty()) {
        if (!sourceModel()->data(sourceIndex, NotesStore::RoleTagGuids).toStringList().contains(m_filterTagGuid)) {
            return false;
        }
    }
    if (m_onlyReminders) {
        if (!sourceModel()->data(sourceIndex, NotesStore::RoleReminder).toBool()) {
            return false;
        }
    }
    if (m_onlySearchResults) {
        Note *note = NotesStore::instance()->note(sourceModel()->data(sourceIndex, NotesStore::RoleGuid).toString());
        if (!note->isSearchResult()) {
            return false;
        }
    }
    if (!m_showDeleted) {
        if (NotesStore::instance()->data(sourceIndex, NotesStore::RoleDeleted).toBool()) {
            return false;
        }
    }
    return true;
}

bool Notes::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
    QVariant leftValue = sourceModel()->data(left, sortRole()).toString();
    QVariant rightValue = sourceModel()->data(right, sortRole()).toString();

    if (leftValue == rightValue) {
        return sourceModel()->data(left, NotesStore::RoleTitle).toString() < sourceModel()->data(right, NotesStore::RoleTitle).toString();
    }

    return leftValue < rightValue;
}
