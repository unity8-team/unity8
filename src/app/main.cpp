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

#include "camerahelper.h"

#include <QtGui/QGuiApplication>
#include <QtQuick/QQuickView>
#include <QtQml/QtQml>

#include <QDebug>

int main(int argc, char *argv[])
{
    QGuiApplication a(argc, argv);
    QQuickView view;
    view.setResizeMode(QQuickView::SizeRootObjectToView);

    // Set up import paths
    QStringList importPathList = view.engine()->importPathList();
    importPathList.append(QDir::currentPath() + "/../plugin/");

    QStringList args = a.arguments();
    qDebug() << "got args" << args;
    for (int i = 0; i < args.count(); i++) {
        if (args.at(i) == "-I" && args.count() > i + 1) {
            QString addedPath = args.at(i+1);
            if (addedPath.startsWith('.')) {
                addedPath = addedPath.right(addedPath.length() - 1);
                addedPath.prepend(QDir::currentPath());
            }
            qDebug() << "appending import path:" << addedPath;
            importPathList.append(addedPath);
        }
    }

    view.engine()->setImportPathList(importPathList);
    qDebug() << "final import paths:" << importPathList;

    // Set up camera helper
    CameraHelper helper;
    view.engine()->rootContext()->setContextProperty("cameraHelper", &helper);

    // load the qml file
    view.setSource(QUrl::fromLocalFile("qml/reminders.qml"));

    view.show();

    return a.exec();
}
