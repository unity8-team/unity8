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

#include "AllApplicationInstances.h"

// unity-api
#include <unity/shell/application/ApplicationInfoInterface.h>
#include <unity/shell/application/ApplicationInstanceInterface.h>

#include <QMetaObject>

Q_LOGGING_CATEGORY(UNITY_ALLAPPINSTANCES, "unity.allappinstances", QtWarningMsg)

#define DEBUG_MSG qCDebug(UNITY_ALLAPPINSTANCES).nospace().noquote() << __func__

using namespace unity::shell::application;

int AllApplicationInstances::rowCount(const QModelIndex &parent) const
{
    return !parent.isValid() ? m_appInstanceList.size() : 0;
}

QVariant AllApplicationInstances::data(const QModelIndex& index, int role) const
{
    if (index.row() < 0 || index.row() >= m_appInstanceList.size())
        return QVariant();

    if (role == ApplicationInstanceRole) {
        return QVariant::fromValue(m_appInstanceList.at(index.row()));
    } else {
        return QVariant();
    }
}

ApplicationInstanceInterface *AllApplicationInstances::get(int index)
{
    if (index > 0 && index < m_appInstanceList.count()) {
        return m_appInstanceList[index];
    } else {
        return nullptr;
    }
}

QAbstractListModel *AllApplicationInstances::applicationsModel() const
{
    return m_applicationsModel;
}

void AllApplicationInstances::setApplicationsModel(QAbstractListModel *value)
{
    if (m_applicationsModel == value) {
        return;
    }

    DEBUG_MSG << "(" << value << ")";

    Q_ASSERT(m_modelState == IdleState);
    m_modelState = ResettingState;

    beginResetModel();

    if (m_applicationsModel) {
        m_appInstanceList.clear();
        m_applications.clear();
        disconnect(m_applicationsModel, 0, this, 0);
    }

    m_applicationsModel = value;

    if (m_applicationsModel) {
        findApplicationRole();

        connect(m_applicationsModel, &QAbstractItemModel::rowsInserted,
                this, [this](const QModelIndex &/*parent*/, int first, int last) {
                    for (int i = first; i <= last; ++i) {
                        auto application = getApplicationFromModelAt(i);
                        addApplication(application);
                    }
                });

        connect(m_applicationsModel, &QAbstractItemModel::rowsAboutToBeRemoved,
                this, [this](const QModelIndex &/*parent*/, int first, int last) {
                    for (int i = first; i <= last; ++i) {
                        auto application = getApplicationFromModelAt(i);
                        removeApplication(application);
                    }
                });

        for (int i = 0; i < m_applicationsModel->rowCount(); ++i) {
            auto application = getApplicationFromModelAt(i);
            addApplication(application);
        }
    }

    endResetModel();
    m_modelState = IdleState;
}

ApplicationInfoInterface *AllApplicationInstances::getApplicationFromModelAt(int index)
{
    QModelIndex modelIndex = m_applicationsModel->index(index);

    QVariant variant =  m_applicationsModel->data(modelIndex, m_applicationRole);

    // variant.value<ApplicationInfoInterface*>() returns null for some reason.
    return static_cast<ApplicationInfoInterface*>(variant.value<QObject*>());
}

void AllApplicationInstances::findApplicationRole()
{
    QHash<int, QByteArray> namesHash = m_applicationsModel->roleNames();

    m_applicationRole = -1;
    for (auto i = namesHash.begin(); i != namesHash.end() && m_applicationRole == -1; ++i) {
        if (i.value() == "application") {
            m_applicationRole = i.key();
        }
    }

    if (m_applicationRole == -1) {
        qFatal("AllApplicationInstances: applicationsModel must have a \"application\" role.");
    }
}

void AllApplicationInstances::addApplication(ApplicationInfoInterface *application)
{
    DEBUG_MSG << "(" << application->appId() << ")";
    Q_ASSERT(!m_applications.contains(application));
    m_applications.append(application);

    ApplicationInstanceListInterface *instanceList = application->instanceList();

    for (int i = 0; i < instanceList->count(); ++i) {
        appendAppInstance(instanceList->get(i));
    }

    connect(instanceList, &QAbstractItemModel::rowsInserted, this,
            [this, application, instanceList](const QModelIndex & /*parent*/, int first, int last)
            {
                for (int i = last; i >= first; --i) {
                    this->appendAppInstance(instanceList->get(i));
                }
            });
}

void AllApplicationInstances::appendAppInstance(ApplicationInstanceInterface *appInstance)
{
    if (m_modelState == IdleState) {
        m_modelState = InsertingState;
        beginInsertRows(QModelIndex(), m_appInstanceList.size() /*first*/, m_appInstanceList.size() /*last*/);
    } else {
        Q_ASSERT(m_modelState == ResettingState);
        // No point in signaling anything if we're resetting the whole model
    }

    m_appInstanceList.append(appInstance);
    connect(appInstance, &QObject::destroyed, this, [this, appInstance](){
        int i = indexOf(appInstance);
        if (i >= 0) {
            removeAt(i);
        }
    });

    if (m_modelState == InsertingState) {
        endInsertRows();
        Q_EMIT countChanged(rowCount());
        m_modelState = IdleState;
    }

    DEBUG_MSG << " after " << toString();
}

void AllApplicationInstances::removeAt(int index)
{
    if (m_modelState == IdleState) {
        beginRemoveRows(QModelIndex(), index, index);
        m_modelState = RemovingState;
    } else {
        Q_ASSERT(m_modelState == ResettingState);
        // No point in signaling anything if we're resetting the whole model
    }

    m_appInstanceList.removeAt(index);

    if (m_modelState == RemovingState) {
        endRemoveRows();
        Q_EMIT countChanged(rowCount());
        m_modelState = IdleState;
    }

    DEBUG_MSG << " after " << toString();
}

int AllApplicationInstances::indexOf(ApplicationInstanceInterface *appInstance)
{
    for (int i = 0; i < m_appInstanceList.count(); ++i) {
        if (m_appInstanceList.at(i) == appInstance) {
            return i;
        }
    }
    return -1;
}

void AllApplicationInstances::removeApplication(ApplicationInfoInterface *application)
{
    DEBUG_MSG << "(" << application->appId() << ")";
    Q_ASSERT(m_applications.contains(application));

    ApplicationInstanceListInterface *instanceList = application->instanceList();

    disconnect(instanceList, 0, this, 0);

    Q_ASSERT(m_modelState == IdleState);
    m_modelState = RemovingState;

    int i = 0;
    while (i < m_appInstanceList.count()) {
        if (m_appInstanceList.at(i)->application() == application) {
            beginRemoveRows(QModelIndex(), i, i);
            m_appInstanceList.removeAt(i);
            endRemoveRows();
            Q_EMIT countChanged(rowCount());
        } else {
            ++i;
        }
    }

    m_modelState = IdleState;

    DEBUG_MSG << " after " << toString();

    m_applications.removeAll(application);
}

QString AllApplicationInstances::toString()
{
    QString str;
    for (int i = 0; i < m_appInstanceList.count(); ++i) {
        auto appInstance = m_appInstanceList.at(i);

        QString itemStr = QString("(appId=%1,instance=0x%2)")
            .arg(appInstance->application()->appId())
            .arg((qintptr)appInstance, 0, 16);

        if (i > 0) {
            str.append(",");
        }
        str.append(itemStr);
    }
    return str;
}
