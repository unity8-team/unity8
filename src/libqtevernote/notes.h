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

#ifndef NOTES_H
#define NOTES_H

#include "notesstore.h"

#include <QSortFilterProxyModel>

class Notes : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_ENUMS(SortOrder)
    Q_PROPERTY(QString filterNotebookGuid READ filterNotebookGuid WRITE setFilterNotebookGuid NOTIFY filterNotebookGuidChanged)
    Q_PROPERTY(QString filterTagGuid READ filterTagGuid WRITE setFilterTagGuid NOTIFY filterTagGuidChanged)
    Q_PROPERTY(bool onlyReminders READ onlyReminders WRITE setOnlyReminders NOTIFY onlyRemindersChanged)
    Q_PROPERTY(bool onlySearchResults READ onlySearchResults WRITE setOnlySearchResults NOTIFY onlySearchResultsChanged)
    Q_PROPERTY(bool showDeleted READ showDeleted WRITE setShowDeleted NOTIFY showDeletedChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(SortOrder sortOrder READ sortOrder WRITE setSortOrder NOTIFY sortOrderChanged)

public:
    enum SortOrder {
        SortOrderDateCreatedNewest,
        SortOrderDateCreatedOldest,
        SortOrderDateUpdatedNewest,
        SortOrderDateUpdatedOldest,
        SortOrderTitleAscending,
        SortOrderTitleDescending
    };

    explicit Notes(QObject *parent = 0);

    QString filterNotebookGuid() const;
    void setFilterNotebookGuid(const QString &notebookGuid);

    QString filterTagGuid() const;
    void setFilterTagGuid(const QString &tagGuid);

    bool onlyReminders() const;
    void setOnlyReminders(bool onlyReminders);

    bool onlySearchResults() const;
    void setOnlySearchResults(bool onlySearchResults);

    bool showDeleted() const;
    void setShowDeleted(bool showDeleted);

    bool loading() const;
    QString error() const;
    int count() const;

    Q_INVOKABLE Note* note(const QString &guid);

    Q_INVOKABLE int sectionCount(const QString &sectionRole, const QString &section);

    SortOrder sortOrder() const;
    void setSortOrder(SortOrder sortOrder);

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
    bool lessThan(const QModelIndex &left, const QModelIndex &right) const override;

signals:
    void filterNotebookGuidChanged();
    void filterTagGuidChanged();
    void onlyRemindersChanged();
    void onlySearchResultsChanged();
    void showDeletedChanged();
    void loadingChanged();
    void errorChanged();
    void countChanged();
    void sortOrderChanged();

private:
    QString m_filterNotebookGuid;
    QString m_filterTagGuid;
    bool m_onlyReminders;
    bool m_onlySearchResults;
    bool m_showDeleted;
    SortOrder m_sortOrder;
};

#endif // NOTES_H
