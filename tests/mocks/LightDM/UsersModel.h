/*
 * Copyright (C) 2013 Canonical, Ltd.
 * Copyright (C) 2010-2011 David Edmundson.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author: David Edmundson <kde@davidedmundson.co.uk>
 */

#ifndef UNITY_MOCK_USERSMODEL_H
#define UNITY_MOCK_USERSMODEL_H

#include <QtCore/QString>
#include <QtCore/QSharedDataPointer>
#include <QAbstractListModel>


namespace QLightDM
{
class UsersModelPrivate;

class Q_DECL_EXPORT UsersModel : public QAbstractListModel
{
    Q_OBJECT

    Q_ENUMS(UserModelRoles)

public:
    explicit UsersModel(QObject *parent = 0);
    virtual ~UsersModel();

    enum UserModelRoles {NameRole = Qt::UserRole,
                         RealNameRole,
                         LoggedInRole,
                         BackgroundRole,
                         SessionRole,
                         HasMessagesRole,
                         ImagePathRole,
                         BackgroundPathRole,
                         UidRole
    };

    int rowCount(const QModelIndex &parent) const;
    QVariant data(const QModelIndex &index, int role) const;

private:
    UsersModelPrivate * const d_ptr;
    Q_DECLARE_PRIVATE(UsersModel)
};

}

#endif // UNITY_MOCK_USERSMODEL_H
