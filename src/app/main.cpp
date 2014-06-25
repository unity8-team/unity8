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
#include "preferences.h"

#include <QtGui/QGuiApplication>
#include <QtQuick/QQuickView>
#include <QtQml/QtQml>
#include <QLibrary>
#include <QDir>

#include <QDebug>

int main(int argc, char *argv[])
{
    QGuiApplication a(argc, argv);
    QQuickView view;
    view.setResizeMode(QQuickView::SizeRootObjectToView);

    // Set up import paths
    QStringList importPathList = view.engine()->importPathList();
    // Prepend the location of the plugin in the build dir,
    // so that Qt Creator finds it there, thus overriding the one installed
    // in the sistem if there is one
    importPathList.prepend(QCoreApplication::applicationDirPath() + "/../plugin/");

    QStringList args = a.arguments();
    if (args.contains("-h") || args.contains("--help")) {
        qDebug() << "usage: " + args.at(0) + " [-p|--phone] [-t|--tablet] [-h|--help] [-I <path>]";
        qDebug() << "    -p|--phone    If running on Desktop, start in a phone sized window.";
        qDebug() << "    -t|--tablet   If running on Desktop, start in a tablet sized window.";
        qDebug() << "    -h|--help     Print this help.";
        qDebug() << "    -I <path>     Give a path for an additional QML import directory. May be used multiple times.";

        // This is handled in the plugin. Just adding here for the --help
        qDebug() << "    -s|--sandbox  Connect to sandbox.evernote.com instead of evernote.com.";

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

    if (args.contains(QLatin1String("-testability")) || getenv("QT_LOAD_TESTABILITY")) {
        QLibrary testLib(QLatin1String("qttestability"));
        if (testLib.load()) {
            typedef void (*TasInitialize)(void);
            TasInitialize initFunction = (TasInitialize)testLib.resolve("qt_testability_init");
            if (initFunction) {
                initFunction();
            } else {
                qCritical("Library qttestability resolve failed!");
            }
        } else {
            qCritical("Library qttestability load failed!");
        }
    }

    view.engine()->rootContext()->setContextProperty("tablet", QVariant(false));
    view.engine()->rootContext()->setContextProperty("phone", QVariant(false));
    if (args.contains("-t") || args.contains("--tablet")) {
        qDebug() << "running in tablet mode";
        view.engine()->rootContext()->setContextProperty("tablet", QVariant(true));
    } else if (args.contains("-p") || args.contains("--phone")){
        qDebug() << "running in phone mode";
        view.engine()->rootContext()->setContextProperty("phone", QVariant(true));
    } else if (qgetenv("QT_QPA_PLATFORM") != "ubuntumirclient") {
        // Default to tablet size on X11
        view.engine()->rootContext()->setContextProperty("tablet", QVariant(true));
    }

    view.engine()->setImportPathList(importPathList);

    // Set up camera helper
    CameraHelper helper;
    view.engine()->rootContext()->setContextProperty("cameraHelper", &helper);

    // Set up account preferences
    Preferences preferences;
    view.engine()->rootContext()->setContextProperty("preferences", &preferences);

    QString qmlfile;
    const QString filePath = QLatin1String("qml/reminders.qml");
    QStringList paths = QStandardPaths::standardLocations(QStandardPaths::DataLocation);
    paths.prepend(QDir::currentPath());
    paths.prepend(QCoreApplication::applicationDirPath());
    Q_FOREACH (const QString &path, paths) {
        QString myPath = path + QLatin1Char('/') + filePath;
        if (QFile::exists(myPath)) {
            qmlfile = myPath;
            break;
        }
    }
    // sanity check
    if (qmlfile.isEmpty()) {
        qFatal("File: %s does not exist at any of the standard paths!", qPrintable(filePath));
    }

    // Make sure our cache dir exists. It'll be used all over in this app.
    // We need to set the applicationName for that.
    // It'll be overwritten again when qml loads but we need it already now.
    // So if you want to change it, make sure to find all the places where it is set, not just here :D
    QCoreApplication::setApplicationName("com.ubuntu.reminders");

    QDir cacheDir(QStandardPaths::standardLocations(QStandardPaths::CacheLocation).first());
    if (!cacheDir.exists()) {
        qDebug() << "creating cacheDir:" << cacheDir.absolutePath();
        cacheDir.mkpath(cacheDir.absolutePath());
    }

    qDebug() << "using main qml file from:" << qmlfile;
    view.setSource(QUrl::fromLocalFile(qmlfile));
    view.show();

    return a.exec();
}
