/*
 * Copyright (C) 2015 Canonical, Ltd.
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

#include <uscorientationcontroller.h>

#include <QDBusInterface>
#include <QDBusPendingCall>
#include <QDBusReply>

USCOrientationController::USCOrientationController(QObject *parent):
    QObject(parent),
    m_angle(0)
{
    m_screenInterface = new QDBusInterface("com.canonical.Unity.Screen",
                                         "/com/canonical/Unity/Screen",
                                         "com.canonical.Unity.Screen",
                                         QDBusConnection::systemBus(), this);
    setAngle(0);
}

int USCOrientationController::angle() const
{
    return m_angle;
}

void USCOrientationController::setAngle(int angle)
{
    if (m_angle != angle) {
        m_angle = angle;
        unsigned int screenId = 0;
        // Seems unity and mir rotate different directions:
        // Mir: clockwise, Unity: counter-clockwise
        // To work around that, let's swap 90/270 here
        if (angle == 90) {
            angle = 270;
        } else if (angle == 270) {
            angle = 90;
        }
        m_screenInterface->asyncCall("overrideOrientation", screenId, angle);
        Q_EMIT angleChanged();
    }
}
