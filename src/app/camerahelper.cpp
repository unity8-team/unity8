/*
 * Copyright: 2013 - 2014 Canonical, Ltd
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
 *          Riccardo Padovani <rpadovani@ubuntu.com>
 */

#include "camerahelper.h"

#include <QStandardPaths>
#include <QCoreApplication>
#include <QImage>
#include <QTransform>
#include <QDebug>

CameraHelper::CameraHelper(QObject *parent):
    QObject(parent)
{

}

QString CameraHelper::importLocation() const
{
    QString homePath = QStandardPaths::standardLocations(QStandardPaths::HomeLocation).first();
    QString appName = QCoreApplication::applicationName();
    return  homePath + "/.cache/" + appName + "/tempImage.jpg";
}

bool CameraHelper::rotate(const QString &imageFile, int angle)
{
    QImage image;
    if (!image.load(imageFile)) {
        return false;
    }
    QTransform transform;
    transform.rotate(angle);
    image = image.transformed(transform);
    return image.save(imageFile);
}

bool CameraHelper::removeTemp() 
{
    const char* location = importLocation().toUtf8();
    if(remove(location) != 0 ) {
        qDebug() << "Error deleting temporary image";
    } else {
        qDebug() << "Temporary image deleted";
    }
  return 0;
}
