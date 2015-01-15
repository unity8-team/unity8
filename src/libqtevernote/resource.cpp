/*
 * Copyright: 2013 Canonical, Ltd
 *
 * This file is part of reminders
 *
 * reminders is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
 */

#include "resource.h"
#include "notesstore.h"

#include <QFile>
#include <QStandardPaths>
#include <QDebug>
#include <QCryptographicHash>
#include <QFileInfo>
#include <QDir>

Resource::Resource(const QByteArray &data, const QString &hash, const QString &fileName, const QString &type, QObject *parent):
    QObject(parent),
    m_hash(hash),
    m_fileName(fileName),
    m_type(type)
{

    m_filePath = QStandardPaths::standardLocations(QStandardPaths::CacheLocation).first() + "/" + NotesStore::instance()->username() + "/" + hash + "." + type.split('/').last();

    QFile file(m_filePath);
    if (!data.isEmpty() && !file.exists()) {

        if (!file.open(QFile::WriteOnly)) {
            qWarning() << "error writing file" << m_filePath;
            return;
        }
        file.write(data);
        file.close();
    }
}

bool Resource::isCached(const QString &hash)
{
    QDir cacheDir(QStandardPaths::standardLocations(QStandardPaths::CacheLocation).first() + "/" + NotesStore::instance()->username());
    foreach (const QString fi, cacheDir.entryList()) {
        if (fi.contains(hash)) {
            return true;
        }
    }
    return false;
}

Resource::Resource(const QString &path, QObject *parent):
    QObject(parent)
{

    QFile file(path);
    if (!file.open(QFile::ReadOnly)) {
        qWarning() << "Cannot open file for reading...";
        return;
    }
    QByteArray fileContent = file.readAll();
    file.close();

    m_hash = QCryptographicHash::hash(fileContent, QCryptographicHash::Md5).toHex();
    m_fileName = path.split('/').last();
    if (m_fileName.endsWith(".png")) {
        m_type = "image/png";
    } else if (m_fileName.endsWith(".jpg") || m_fileName.endsWith(".jpeg")) {
        m_type = "image/jpeg";
    } else if (m_fileName.endsWith(".gif")) {
        m_type = "image/gif";
    } else {
        qWarning() << "cannot determine mime type of file" << m_fileName;
    }

    m_filePath = QStandardPaths::standardLocations(QStandardPaths::CacheLocation).first() + "/" + NotesStore::instance()->username() + "/" + m_hash + "." + m_type.split('/').last();

    QFile copy(m_filePath);
    if (!copy.exists()) {

        if (!copy.open(QFile::WriteOnly)) {
            qWarning() << "error writing file" << m_filePath;
            return;
        }
        copy.write(fileContent);
        copy.close();
    }
}

QString Resource::hash() const
{
    return m_hash;
}

QString Resource::type() const
{
    return m_type;
}

QByteArray Resource::imageData(const QSize &size)
{
    if (!m_type.startsWith("image/")) {
        return QByteArray();
    }

    QString finalFilePath = m_filePath;
    if (size.isValid() && !size.isNull()) {
        finalFilePath = m_filePath + "_" + QString::number(size.width()) + "x" + QString::number(size.height()) + ".jpg";
        QFileInfo fi(finalFilePath);
        if (!fi.exists()) {
            QImage image(m_filePath);
            if (size.height() > 0 && size.width() > 0) {
                image = image.scaled(size);
            } else if (size.height() > 0) {
                image = image.scaledToHeight(size.height());
            } else {
                image = image.scaledToWidth(size.width());
            }
            image.save(finalFilePath);
        }
    }

    QFile file(finalFilePath);
    if (file.open(QFile::ReadOnly)) {
        return file.readAll();
    }
    return QByteArray();
}

QString Resource::fileName() const
{
    return m_fileName;
}

QByteArray Resource::data() const
{
    QFile file(m_filePath);
    if (file.open(QFile::ReadOnly)) {
        return file.readAll();
    }
    return QByteArray();
}
