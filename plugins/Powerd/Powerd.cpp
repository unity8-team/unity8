/*
 * Copyright (C) 2013 Canonical, Ltd.
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
 * Author: Michael Terry <michael.terry@canonical.com>
 */

#include "Powerd.h"
#include <ubuntu/application/sensors/proximity.h>

Powerd::Powerd(QObject* parent)
  : QObject(parent),
    m_powerd(NULL),
    m_proximitySensor(ua_sensors_proximity_new()) // Note: seems no way to free...
{
    m_powerd = new QDBusInterface("com.canonical.powerd",
                                  "/com/canonical/powerd",
                                  "com.canonical.powerd",
                                  QDBusConnection::SM_BUSNAME(), this);

    m_powerd->connection().connect("com.canonical.powerd",
                                   "/com/canonical/powerd",
                                   "com.canonical.powerd",
                                   "DisplayPowerStateChange",
                                   this,
                                   SIGNAL(displayPowerStateChange(int, unsigned int)));

    if (m_proximitySensor) {
        ua_sensors_proximity_set_reading_cb(m_proximitySensor,
                                            onProximityEvent,
                                            this);
    }
}

bool Powerd::getNearProximity()
{
    return m_nearProximity;
}

void Powerd::onProximityEvent(UASProximityEvent *event, void *context)
{
    auto powerd = (Powerd*)context;

    bool isNear = uas_proximity_event_get_distance(event) == U_PROXIMITY_NEAR;
    if (isNear != powerd->m_nearProximity) {
        powerd->m_nearProximity = isNear;
        Q_EMIT powerd->nearProximityChanged();
    }
}
