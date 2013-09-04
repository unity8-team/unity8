/*
 * Copyright (C) 2012,2013 Canonical, Ltd.
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
 * Authors: Gerry Boland <gerry.boland@canonical.com>
 *          Michael Terry <michael.terry@canonical.com>
 */

#ifndef UNITY_POWERD_H
#define UNITY_POWERD_H

#include <QtCore/QObject>
#include <QtDBus/QDBusInterface>

typedef void UASProximityEvent;
typedef void UASensorsProximity;

class Powerd: public QObject
{
    Q_OBJECT
    Q_ENUMS(Status)
    Q_FLAGS(DisplayFlag DisplayFlags)

    Q_PROPERTY(bool nearProximity
               READ getNearProximity
               NOTIFY nearProximityChanged)

public:
    enum DisplayFlag {
        UseProximity          = 1, // Use proximity sensor to override screen state
        DisableAutoBrightness = 2, // Force autobrightness to be disabled
        Bright                = 4, // Request the screen to stay bright
    };
    Q_DECLARE_FLAGS(DisplayFlags, DisplayFlag)

    enum Status {
        Off,
        On,
    };

    explicit Powerd(QObject *parent = 0);

    bool getNearProximity();

Q_SIGNALS:
    void displayPowerStateChange(int status, unsigned int flags);
    void nearProximityChanged();

private:
    static void onProximityEvent(UASProximityEvent *event, void *context);

    QDBusInterface *m_powerd;
    bool m_nearProximity;
    UASensorsProximity *m_proximitySensor;
};

#endif
