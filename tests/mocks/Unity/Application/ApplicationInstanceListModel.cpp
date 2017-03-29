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

#include "ApplicationInstanceListModel.h"

#include <unity/shell/application/ApplicationInstanceInterface.h>

using namespace unity::shell::application;

ApplicationInstanceListModel::ApplicationInstanceListModel(QObject *parent)
    : ApplicationInstanceListInterface(parent)
{
}

int ApplicationInstanceListModel::rowCount(const QModelIndex &parent) const
{
    return !parent.isValid() ? m_appInstanceList.size() : 0;
}

QVariant ApplicationInstanceListModel::data(const QModelIndex& index, int role) const
{
    if (index.row() < 0 || index.row() >= m_appInstanceList.size())
        return QVariant();

    if (role == ApplicationInstanceRole) {
        ApplicationInstanceInterface *appInstance = m_appInstanceList.at(index.row());
        return QVariant::fromValue(appInstance);
    } else {
        return QVariant();
    }
}

ApplicationInstanceInterface *ApplicationInstanceListModel::get(int index)
{
    return m_appInstanceList[index];
}

void ApplicationInstanceListModel::append(unity::shell::application::ApplicationInstanceInterface *appInstance)
{
    beginInsertRows(QModelIndex(), m_appInstanceList.size(), m_appInstanceList.size());
    m_appInstanceList.append(appInstance);
    connect(appInstance, &QObject::destroyed, this, [this, appInstance](){ this->remove(appInstance); });
    endInsertRows();
    Q_EMIT countChanged(m_appInstanceList.count());
}

void ApplicationInstanceListModel::remove(unity::shell::application::ApplicationInstanceInterface *appInstance)
{
    int i = m_appInstanceList.indexOf(appInstance);
    if (i != -1) {
        beginRemoveRows(QModelIndex(), i, i);
        m_appInstanceList.removeAt(i);
        endRemoveRows();
        Q_EMIT countChanged(m_appInstanceList.count());
    }
}
