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

#include "inputprovider.h"
#include "inputprovideradaptor.h"

#include <linux/input.h>
#include <unistd.h>

InputProvider::InputProvider(QObject *parent):
    QObject(parent),
    m_adaptor(new InputProviderAdaptor(this))
{

}

void InputProvider::setMousePosition(int x, int y)
{
    m_x = x;
    m_y = y;

    if (!m_file.isOpen()) {
        return;
    }

    struct input_event event;
    memset(&event, 0, sizeof(event));
    clock_gettime(CLOCK_MONOTONIC, (timespec*)&event.time);
    event.type = EV_ABS;
    event.code = ABS_X;
    event.value = m_x;
    write(m_file.handle(), &event, sizeof(event));
    event.code = ABS_Y;
    event.value = m_y;
    write(m_file.handle(), &event, sizeof(event));
}

QString InputProvider::cursor() const
{
    return m_cursor;
}

void InputProvider::setCursor(const QString &cursor)
{
    if (m_cursor != cursor) {
        m_cursor = cursor;
        Q_EMIT cursorChanged();
        QVariantMap propertyChanges;
        propertyChanges["cursor"] = cursor;
        Q_EMIT PropertiesChanged("org.aethercast.InputProvider", propertyChanges, QStringList());
    }
}

void InputProvider::NewConnection(const QDBusUnixFileDescriptor &fd, const QVariantMap &options)
{
    Q_UNUSED(options)
    qDebug() << "have new connection" << fd.fileDescriptor();

    if (m_file.isOpen()) {
        qWarning() << "Already have an Aethercast connection. Closing old one.";
        m_file.close();
    }

    if (!m_file.open(fd.fileDescriptor(), QFile::WriteOnly)) {
        qWarning() << "Cannot open file for writing. Streaming mouse cursor to Aethercast will not work.";
        return;
    }

    struct input_event event;
    memset(&event, 0, sizeof(event));
    clock_gettime(CLOCK_MONOTONIC, (timespec*)&event.time);
    event.type = EV_ABS;
    event.code = ABS_X;
    event.value = m_x;
    write(m_file.handle(), &event, sizeof(event));
    event.code = ABS_Y;
    event.value = m_y;
    write(m_file.handle(), &event, sizeof(event));
}

void InputProvider::RequestDisconnection()
{
    m_file.close();
}
