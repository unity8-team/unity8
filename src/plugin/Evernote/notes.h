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
    Q_PROPERTY(QString filterNotebookGuid READ filterNotebookGuid WRITE setFilterNotebookGuid NOTIFY filterNotebookGuidChanged)
    Q_PROPERTY(bool onlyReminders READ onlyReminders WRITE setOnlyReminders NOTIFY onlyRemindersChanged)
    Q_PROPERTY(bool onlySearchResults READ onlySearchResults WRITE setOnlySearchResults NOTIFY onlySearchResultsChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)

public:
    explicit Notes(QObject *parent = 0);

    QString filterNotebookGuid() const;
    void setFilterNotebookGuid(const QString &notebookGuid);

    bool onlyReminders() const;
    void setOnlyReminders(bool onlyReminders);

    bool onlySearchResults() const;
    void setOnlySearchResults(bool onlySearchResults);

    bool loading() const;

    Q_INVOKABLE Note* note(const QString &guid);

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const;

signals:
    void filterNotebookGuidChanged();
    void onlyRemindersChanged();
    void onlySearchResultsChanged();
    void loadingChanged();

private:
    QString m_filterNotebookGuid;
    bool m_onlyReminders;
    bool m_onlySearchResults;
};

#endif // NOTES_H
