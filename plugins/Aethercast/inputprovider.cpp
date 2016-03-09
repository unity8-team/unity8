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

#include <QStandardPaths>


InputProvider::InputProvider(QObject *parent):
    QObject(parent),
    m_adaptor(new InputProviderAdaptor(this))
{

}

void InputProvider::setMouseX(int x)
{
    m_x = x;

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

    Q_EMIT mouseXChanged();
}

void InputProvider::setMouseY(int y)
{
    m_y = y;

    if (!m_file.isOpen()) {
        return;
    }

    struct input_event event;
    memset(&event, 0, sizeof(event));
    clock_gettime(CLOCK_MONOTONIC, (timespec*)&event.time);
    event.type = EV_ABS;
    event.code = ABS_Y;
    event.value = m_y;
    write(m_file.handle(), &event, sizeof(event));

    Q_EMIT mouseYChanged();
}

int InputProvider::mouseX() const
{
    return m_x;
}

int InputProvider::mouseY() const
{
    return m_y;
}

QString InputProvider::cursorSource() const
{
    return m_cursorSource;
}

QString InputProvider::cursor() const
{
    return m_cursor;
}

void InputProvider::setCursorSource(const QString &cursorSource)
{
    if (m_cursorSource == cursorSource) {
        return;
    }

//    QStringList parts = cursorSource.split('/');
//    if (parts.count() != 2) {
//        qWarning() << "Invalid cursor image. Needs to be \"theme/file\"";
//        return;
//    }
//    QString theme = parts.first();
//    QString cursor = parts.last();

//    // Check if we have this in cache
//    QString cachePath = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
//    QFile cacheFile(cachePath + QStringLiteral("/cursors/") + theme + QStringLiteral("/") + cursor + QStringLiteral(".png"));

//    if (!cacheFile.exists()) {
//        XcursorImages *xcursorImages = XcursorLibraryLoadImages(QFile::encodeName(parts.last()), QFile::encodeName(parts.first()), 32);
//        if (!xcursorImages || xcursorImages->nimage == 0) {
//            qWarning() << "Error reading XcursorsImages for" << theme << cursor;
//            return;
//        }

//        XcursorImage *xcursorImage = xcursorImages->images[0];

//        QImage qimage = QImage((uchar*)xcursorImage->pixels, xcursorImage->width, xcursorImage->height, QImage::Format_ARGB32);
//    }

//    m_cursor = cacheFile.fileName();
//    Q_EMIT cursorChanged();

//    QVariantMap propertyChanges;
//    propertyChanges["cursor"] = cursor;
//    Q_EMIT PropertiesChanged("org.aethercast.InputProvider", propertyChanges, QStringList());
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
