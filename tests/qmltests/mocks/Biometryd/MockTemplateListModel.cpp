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

#include "MockTemplateListModel.h"


MockTemplateListModel::MockTemplateListModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_uid(0)
    , m_ts(nullptr)
{

}

int MockTemplateListModel::uid() const
{
    return m_uid;
}

void MockTemplateListModel::setUid(const int &uid);
{
    m_uid = uid;
    Q_EMIT (uidChanged());
}

MockTemplateStore* MockTemplateListModel::templateStore() const
{
    return m_ts;
}

void MockTemplateListModel::setTemplateStore(const MockTemplateStore* templateStore)
{
    m_ts = templateStore;
    Q_EMIT (templateStoreChanged());
}


QVariant MockTemplateListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return QVariant();

    if (role == Qt::DisplayRole)
        return m_templates.value(index.row());

    return QVariant();
}

void MockTemplateListModel::mockAddFingerprint(const QString &id)
{
    int row = m_templates.size();

    beginInsertRows(QModelIndex(), row, row);
    m_templates.insert(row, id);
    endInsertRows();
}

void MockTemplateListModel::mockRemoveFingerprint(const QString &id)
{
    int row = m_templates.indexOf(id);

    if (row < 0) {
        qWarning() << "tried removing non-existent fingerprint:" << id;
        return;
    }

    beginRemoveRows(QModelIndex(), row, row);
    m_templates.removeAt(row);
    endRemoveRows();
}

int MockTemplateListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    else
        return m_templates.size();
}
