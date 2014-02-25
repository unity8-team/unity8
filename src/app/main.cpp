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
#include "accountpreference.h"

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
    if (args.contains("-h") || args.contains("--help")) {
        qDebug() << "usage: " + args.at(0) + " [-p|--phone] [-t|--tablet] [-h|--help] [-I <path>]";
        qDebug() << "    -p|--phone    If running on Desktop, start in a phone sized window.";
        qDebug() << "    -t|--tablet   If running on Desktop, start in a tablet sized window.";
        qDebug() << "    -h|--help     Print this help.";
        qDebug() << "    -I <path>     Give a path for an additional QML import directory. May be used multiple times.";
        return 0;
    }

    for (int i = 0; i < args.count(); i++) {
        if (args.at(i) == "-I" && args.count() > i + 1) {
            QString addedPath = args.at(i+1);
            if (addedPath.startsWith('.')) {
                addedPath = addedPath.right(addedPath.length() - 1);
                addedPath.prepend(QDir::currentPath());
            }
            importPathList.append(addedPath);
        }
    }

    view.engine()->rootContext()->setContextProperty("tablet", false);
    view.engine()->rootContext()->setContextProperty("phone", false);
    if (args.contains("-t") || args.contains("--tablet")) {
        qDebug() << "running in tablet mode";
        view.engine()->rootContext()->setContextProperty("tablet", true);
    } else if (args.contains("-p") || args.contains("--phone")){
        qDebug() << "running in phone mode";
        view.engine()->rootContext()->setContextProperty("phone", true);
    } else if (qgetenv("QT_QPA_PLATFORM") != "ubuntumirclient") {
        // Default to tablet size on X11
        view.engine()->rootContext()->setContextProperty("tablet", true);
    }

    view.engine()->setImportPathList(importPathList);

    // Set up camera helper
    CameraHelper helper;
    view.engine()->rootContext()->setContextProperty("cameraHelper", &helper);

    // Set up account preferences
    AccountPreference preferences;
    view.engine()->rootContext()->setContextProperty("accountPreference", &preferences);

    // load the qml file
    QFileInfo fi("qml/reminders.qml");
    if (fi.exists()) {
        view.setSource(QUrl::fromLocalFile("qml/reminders.qml"));
    } else {
        view.setSource(QUrl::fromLocalFile("/usr/share/reminders/qml/reminders.qml"));
    }

    view.show();

    return a.exec();
}
