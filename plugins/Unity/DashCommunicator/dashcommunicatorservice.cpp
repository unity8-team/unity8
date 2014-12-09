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
#include <QTimer>

DashCommunicatorService::DashCommunicatorService(QObject *parent):
    QObject(parent)
{
    // Delay creation of the DBus service. If it happens too early it can cause a shell deadlock,
    // where two blocking events (introspecting this service, and deciding surface geometry) happen
    // at the same time.
    QTimer::singleShot(0, this, SLOT(create()));
}

void DashCommunicatorService::create()
{
    m_dbusService = new DBusDashCommunicatorService(this);
    connect(m_dbusService, &DBusDashCommunicatorService::setCurrentScopeRequested, this, &DashCommunicatorService::setCurrentScopeRequested);
}
