/*
 * Copyright: 2013 Canonical, Ltd
 *
 * This file is part of reminders
 *
 * reminders is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
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

#ifndef CAMERAHELPER_H
#define CAMERAHELPER_H

#include <QObject>

class CameraHelper: public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString importLocation READ importLocation CONSTANT)
public:
    CameraHelper(QObject *parent = 0);

    QString importLocation() const;

    Q_INVOKABLE bool rotate(const QString &imageFile, int angle);
};

#endif
