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

#include "appdrawerproxymodel.h"

#include <unity/shell/launcher/LauncherItemInterface.h>

#include <QDebug>

AppDrawerProxyModel::AppDrawerProxyModel(QObject *parent):
    QSortFilterProxyModel(parent)
{
    setSortRole(AppDrawerModelInterface::RoleName);
    setSortLocaleAware(true);
    sort(0);

    connect(this, &QAbstractListModel::rowsInserted, this, &AppDrawerProxyModel::countChanged);
    connect(this, &QAbstractListModel::rowsRemoved, this, &AppDrawerProxyModel::countChanged);
    connect(this, &QAbstractListModel::layoutChanged, this, &AppDrawerProxyModel::countChanged);
}

QAbstractItemModel *AppDrawerProxyModel::source() const
{
    return m_source;
}

void AppDrawerProxyModel::setSource(QAbstractItemModel *source)
{
    if (m_source != source) {
        m_source = source;
        setSourceModel(m_source);
        setSortRole(m_sortBy == SortByAToZ ? AppDrawerModelInterface::RoleName : AppDrawerModelInterface::RoleUsage);
        connect(m_source, &QAbstractItemModel::rowsRemoved, this, &AppDrawerProxyModel::invalidate);
        connect(m_source, &QAbstractItemModel::rowsInserted, this, &AppDrawerProxyModel::invalidate);
        Q_EMIT sourceChanged();
    }
}

AppDrawerProxyModel::GroupBy AppDrawerProxyModel::group() const
{
    return m_group;
}

void AppDrawerProxyModel::setGroup(AppDrawerProxyModel::GroupBy group)
{
    if (m_group != group) {
        m_group = group;
        Q_EMIT groupChanged();
        invalidateFilter();
    }
}

QString AppDrawerProxyModel::filterLetter() const
{
    return m_filterLetter;
}

void AppDrawerProxyModel::setFilterLetter(const QString &filterLetter)
{
    if (m_filterLetter != filterLetter) {
        m_filterLetter = filterLetter;
        Q_EMIT filterLetterChanged();
        invalidateFilter();
    }
}

QString AppDrawerProxyModel::filterString() const
{
    return m_filterString;
}

void AppDrawerProxyModel::setFilterString(const QString &filterString)
{
    if (m_filterString != filterString) {
        m_filterString = filterString;
        Q_EMIT filterStringChanged();
        invalidateFilter();
    }
}

AppDrawerProxyModel::SortBy AppDrawerProxyModel::sortBy() const
{
    return m_sortBy;
}

void AppDrawerProxyModel::setSortBy(AppDrawerProxyModel::SortBy sortBy)
{
    if (m_sortBy != sortBy) {
        m_sortBy = sortBy;
        Q_EMIT sortByChanged();
        setSortRole(m_sortBy == SortByAToZ ? AppDrawerModelInterface::RoleName : AppDrawerModelInterface::RoleUsage);
        sort(0);
    }
}

int AppDrawerProxyModel::count() const
{
    return rowCount();
}

QVariant AppDrawerProxyModel::data(const QModelIndex &index, int role) const
{
    const QModelIndex idx = mapToSource(index);
    if (role == Qt::UserRole) {
        const QString name = m_source->data(idx, AppDrawerModelInterface::RoleName).toString();
        return !name.isEmpty() ? name.at(0).toUpper() : QChar();
    }
    return m_source->data(idx, role);
}

QHash<int, QByteArray> AppDrawerProxyModel::roleNames() const
{
    if (m_source) {
        QHash<int, QByteArray> roles = m_source->roleNames();
        roles.insert(Qt::UserRole, "letter");
        return roles;
    }
    return QHash<int, QByteArray>();
}

bool AppDrawerProxyModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    Q_UNUSED(source_parent)

    const QModelIndex idx{m_source->index(source_row, 0)};

    if (m_group == GroupByAToZ && source_row > 0) {
        const QString currentName = m_source->data(idx, AppDrawerModelInterface::RoleName).toString();
        const QChar currentLetter = !currentName.isEmpty() ? currentName.at(0) : QChar();
        const QString previousName = m_source->data(m_source->index(source_row - 1,0 ), AppDrawerModelInterface::RoleName).toString();
        const QChar previousLetter = !previousName.isEmpty() ? previousName.at(0) : QChar();
        if (currentLetter.toLower() == previousLetter.toLower()) {
            return false;
        }
    } else if (m_group == GroupByAll && source_row > 0) {
        return false;
    }

    if (!m_filterLetter.isEmpty()) {
        const QString currentName = m_source->data(idx, AppDrawerModelInterface::RoleName).toString();
        const QString currentLetter = !currentName.isEmpty() ? QString(currentName.at(0)) : QString();
        if (currentLetter.toLower() != m_filterLetter.toLower()) {
            return false;
        }
    }
    if (!m_filterString.isEmpty()) {
        const auto roles = {AppDrawerModelInterface::RoleAppId, AppDrawerModelInterface::RoleName,
                            AppDrawerModelInterface::RoleDescription, AppDrawerModelInterface::RoleKeywords};
        bool found = false;
        Q_FOREACH (const auto &role, roles) {
            const QString data = m_source->data(idx, role).toString();
            if (data.contains(m_filterString, Qt::CaseInsensitive)) {
                found = true;
                break;
            }
        }
        if (!found) {
            return false;
        }
    }
    return true;
}

QString AppDrawerProxyModel::appId(int index) const
{
    if (index >= 0 && index < rowCount()) {
        QModelIndex sourceIndex = mapToSource(this->index(index, 0));

        AppDrawerModelInterface* adm = dynamic_cast<AppDrawerModelInterface*>(m_source);
        if (adm) {
            return adm->data(sourceIndex, AppDrawerModelInterface::RoleAppId).toString();
        }

        AppDrawerProxyModel* adpm = qobject_cast<AppDrawerProxyModel*>(m_source);
        if (adpm) {
            return adpm->appId(sourceIndex.row());
        }
    }
    return QString();
}
