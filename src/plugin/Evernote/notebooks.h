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

#ifndef NOTEBOOKS_H
#define NOTEBOOKS_H

#include "notesstore.h"

#include <QAbstractListModel>

class Notebooks : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        RoleGuid,
        RoleName,
        RoleNoteCount,
        RolePublished,
        RoleLastUpdated,
        RoleLastUpdatedString
    };
    explicit Notebooks(QObject *parent = 0);

    bool loading() const;
    QString error() const;
    int count() const;

    QVariant data(const QModelIndex &index, int role) const;
    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QHash<int, QByteArray> roleNames() const;

    Q_INVOKABLE Notebook *notebook(int index) const;

public slots:
    void refresh();

signals:
    void loadingChanged();
    void errorChanged();
    void countChanged();

private slots:
    void notebookAdded(const QString &guid);
    void notebookRemoved(const QString &guid);

    void nameChanged();
    void noteCountChanged();
    void publishedChanged();
    void lastUpdatedChanged();

private:
    QList<QString> m_list;
};

#endif // NOTEBOOKS_H
