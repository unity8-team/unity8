/*
 * Copyright (C) 2016 Canonical, Ltd.
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
 */

#ifndef APPLICATIONINSTANCELISTMODEL_H
#define APPLICATIONINSTANCELISTMODEL_H

// unity-api
#include <unity/shell/application/ApplicationInstanceListInterface.h>

#include <QList>

class ApplicationInstanceListModel : public unity::shell::application::ApplicationInstanceListInterface
{
    Q_OBJECT
public:
    ApplicationInstanceListModel(QObject *parent = nullptr);

    // QAbstractItemModel methods
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;

    // From unity::shell::application::ApplicationInstanceListInterface
    Q_INVOKABLE unity::shell::application::ApplicationInstanceInterface *get(int index) override;

    // Own methods
    void append(unity::shell::application::ApplicationInstanceInterface*);
    void remove(unity::shell::application::ApplicationInstanceInterface*);

private:
    QList<unity::shell::application::ApplicationInstanceInterface*> m_appInstanceList;
};

#endif // APPLICATIONINSTANCELISTMODEL_H
