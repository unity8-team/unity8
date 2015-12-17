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

#ifndef INPUT_PROVIDER_H
#define INPUT_PROVIDER_H

#include <QDBusConnection>
#include <QDBusUnixFileDescriptor>
#include <QFile>

class InputProviderAdaptor;

class InputProvider: public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString cursor READ cursor)

public:
    InputProvider(QObject *parent = nullptr);

    void setMousePosition(int x, int y);

    QString cursor() const;
    void setCursor(const QString &cursor);

public Q_SLOTS:
    void NewConnection(const QDBusUnixFileDescriptor &fd, const QVariantMap &options);
    void RequestDisconnection();

Q_SIGNALS:
    void cursorChanged();
    void PropertiesChanged(const QString &interface, const QVariantMap &changed, const QStringList &invalid);

private:
    int m_x = 0;
    int m_y = 0;
    QString m_cursor;
    QFile m_file;
    InputProviderAdaptor *m_adaptor;
};

#endif
