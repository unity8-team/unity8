/*
 * Copyright (C) 2016 Canonical, Ltd.
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

#ifndef MOCK_FINGERPRINTREADER_H
#define MOCK_FINGERPRINTREADER_H

#include <QObject>
#include <QString>
#include <QVariant>
#include <QList>
#include <QRect>

class MockFingerprintReader : public QObject

{
    Q_OBJECT
    Q_DISABLE_COPY(MockFingerprintReader)
    Q_PROPERTY(QString isFingerPresent READ isFingerPresent)
    Q_PROPERTY(QString hasMainClusterIdentified READ hasMainClusterIdentified)
    Q_PROPERTY(QString suggestedNextDirection READ suggestedNextDirection)
    Q_PROPERTY(QString masks READ masks)

public:
    explicit MockFingerprintReader(QObject *parent = 0);

    Q_INVOKABLE QString isFingerPresent() const;
    Q_INVOKABLE QString hasMainClusterIdentified() const;
    Q_INVOKABLE QString suggestedNextDirection() const;
    Q_INVOKABLE QString estimatedFingerSize() const;
    Q_INVOKABLE QString masks() const;


Q_SIGNALS:
    void succeeded(const QVariant &result);
    void failed(const QString &reason);
};

#endif // MOCK_FINGERPRINTREADER_H
