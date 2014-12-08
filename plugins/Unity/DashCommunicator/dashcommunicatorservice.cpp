/*
 * Copyright (C) 2014 Canonical, Ltd.
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License version 3, as published by
 * the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranties of MERCHANTABILITY,
 * SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "dashcommunicatorservice.h"

DashCommunicatorService::DashCommunicatorService(QObject *parent):
    QObject(parent)
{
}

bool DashCommunicatorService::enabled() const
{
    return !m_dbusService.isNull();
}

void DashCommunicatorService::setEnabled(const bool enabled)
{
    if (enabled == enabled())
        return;

    if (enabled) {
        m_dbusService = new DBusDashCommunicatorService();
        connect(m_dbusService, &DBusDashCommunicatorService::setCurrentScopeRequested,
                this, &DashCommunicatorService::setCurrentScopeRequested);
    } else {
        m_dbusService.clear();
    }
    Q_EMIT enabledChanged();
}
