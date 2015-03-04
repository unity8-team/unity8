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

#ifndef TAGS_H
#define TAGS_H

#include "notesstore.h"

#include <QAbstractListModel>

class Tags: public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        RoleGuid,
        RoleName,
        RoleNoteCount,
        RoleLoading,
        RoleSynced,
        RoleSyncError
    };
    explicit Tags(QObject *parent = 0);

    bool loading() const;
    int count() const;

    QVariant data(const QModelIndex &index, int role) const;
    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QHash<int, QByteArray> roleNames() const;

    Q_INVOKABLE Tag* tag(int index) const;

public slots:
    void refresh();

signals:
    void loadingChanged();
    void countChanged();

private slots:
    void tagAdded(const QString &guid);
    void tagRemoved(const QString &guid);
    void tagGuidChanged(const QString &oldGuid, const QString &newGuid);

    void nameChanged();
    void noteCountChanged();
    void tagLoadingChanged();
    void syncedChanged();
    void syncErrorChanged();

private:
    QList<QString> m_list;
};

#endif // TAGS_H
