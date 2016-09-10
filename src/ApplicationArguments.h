/*
 * Copyright (C) 2013,2015 Canonical, Ltd.
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
 */


#ifndef APPLICATION_ARGUMENTS_H
#define APPLICATION_ARGUMENTS_H

#include <QObject>
#include <QSize>
#include <QString>

class ApplicationArguments : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString deviceName READ deviceName NOTIFY deviceNameChanged)
    Q_PROPERTY(QString mode READ mode CONSTANT)
    Q_PROPERTY(bool launcherAvailable READ launcherAvailable CONSTANT)
    Q_PROPERTY(bool panelAvailable READ panelAvailable CONSTANT)
    Q_PROPERTY(bool spreadAvailable READ spreadAvailable CONSTANT)
public:
    ApplicationArguments(QObject *parent = nullptr);

    void setDeviceName(const QString &deviceName) {
        if (deviceName != m_deviceName) {
            m_deviceName = deviceName;
            Q_EMIT deviceNameChanged(m_deviceName);
        }
    }
    QString deviceName() const { return m_deviceName; }

    void setMode(const QString &mode) { m_mode = mode; }
    QString mode() const { return m_mode; }

    void setLauncherAvailable(bool available) { m_launcherAvailable = available; }
    bool launcherAvailable() { return m_launcherAvailable; }

    void setPanelAvailable(bool available) { m_panelAvailable = available; }
    bool panelAvailable() { return m_panelAvailable; }

    void setSpreadAvailable(bool available) { m_spreadAvailable = available; }
    bool spreadAvailable() { return m_spreadAvailable; }

Q_SIGNALS:
    void deviceNameChanged(const QString&);

private:
    QString m_deviceName;
    QString m_mode;
    bool m_launcherAvailable = true;
    bool m_panelAvailable = true;
    bool m_spreadAvailable = true;
};

#endif // APPLICATION_ARGUMENTS_H
