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

#ifndef ALLAPPLICATIONINSTANCES_H
#define ALLAPPLICATIONINSTANCES_H

// unity-api
#include <unity/shell/application/ApplicationInstanceListInterface.h>

#include <QList>
#include <QLoggingCategory>

Q_DECLARE_LOGGING_CATEGORY(UNITY_ALLAPPINSTANCES)

namespace unity {
    namespace shell {
        namespace application {
            class ApplicationInfoInterface;
        }
    }
}

class AllApplicationInstances : public unity::shell::application::ApplicationInstanceListInterface
{
    Q_OBJECT

    /**
     * @brief A list model of applications.
     *
     * It's expected to have a role called "application" which returns a ApplicationInfoInterface
     */
    Q_PROPERTY(QAbstractListModel* applicationsModel READ applicationsModel
                                                     WRITE setApplicationsModel
                                                     NOTIFY applicationsModelChanged)

public:
    QAbstractListModel *applicationsModel() const;
    void setApplicationsModel(QAbstractListModel*);

    // ApplicationInstanceListInterface methods
    Q_INVOKABLE unity::shell::application::ApplicationInstanceInterface *get(int index) override;

    // QAbstractItemModel methods
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;

Q_SIGNALS:
    void applicationsModelChanged();

private:
    void addApplication(unity::shell::application::ApplicationInfoInterface *application);
    void removeApplication(unity::shell::application::ApplicationInfoInterface *application);
    void findApplicationRole();
    unity::shell::application::ApplicationInfoInterface *getApplicationFromModelAt(int index);
    void appendAppInstance(unity::shell::application::ApplicationInstanceInterface *appInstance);
    int indexOf(unity::shell::application::ApplicationInstanceInterface *surface);
    void removeAt(int index);
    QString toString();

    QList<unity::shell::application::ApplicationInstanceInterface*> m_appInstanceList;

    // applications that are being monitored
    QList<unity::shell::application::ApplicationInfoInterface *> m_applications;

    QAbstractListModel* m_applicationsModel{nullptr};
    int m_applicationRole{-1};

    enum ModelState {
        IdleState,
        InsertingState,
        RemovingState,
        MovingState,
        ResettingState
    };
    ModelState m_modelState{IdleState};
};

#endif // ALLAPPLICATIONINSTANCES_H
