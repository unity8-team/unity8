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

#ifndef RESOURCE_H
#define RESOURCE_H

#include <QObject>
#include <QString>
#include <QImage>

class Resource: public QObject
{
    Q_OBJECT
    Q_PROPERTY(QByteArray data READ data CONSTANT)
    Q_PROPERTY(QString hash READ hash CONSTANT)
    Q_PROPERTY(QString fileName READ fileName CONSTANT)
    Q_PROPERTY(QString type READ type CONSTANT)

public:
    Resource(const QString &path, QObject *parent = 0);
    Resource(const QByteArray &data, const QString &hash, const QString &fileName, const QString &type, QObject *parent = 0);

    static bool isCached(const QString &hash);

    QByteArray data() const;
    QString hash() const;
    QString fileName() const;
    QString type() const;

    QByteArray imageData(const QSize &size = QSize());

private:
    QString m_hash;
    QString m_fileName;
    QString m_filePath;
    QString m_type;
};

#endif
