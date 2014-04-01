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
 *          Dan Chapman <dpniel@ubuntu.com>
 */

#include "camerahelper.h"
#include "accountpreference.h"

#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QtGui/QGuiApplication>
#include <QtQuick/QQuickView>
#include <QtQml/QtQml>
#include <QLibrary>

#include <QDebug>

int main(int argc, char *argv[])
{
    QGuiApplication a(argc, argv);
    QQuickView view;
    view.setResizeMode(QQuickView::SizeRootObjectToView);

    // Set up import paths
    QStringList importPathList = view.engine()->importPathList();
    importPathList.append(QDir::currentPath() + "/../plugin/");

    QCommandLineParser parser;
    parser.setSingleDashWordOptionMode(QCommandLineParser::ParseAsLongOptions);
    parser.setApplicationDescription(QGuiApplication::translate("main",
        "Simple app that will allow interaction between Ubuntu's API & Evernotes cloud API"));
    parser.addHelpOption();
    QCommandLineOption phoneViewOption(QStringList() << QLatin1String("p") << QLatin1String("phone"), QGuiApplication::translate("main",
        "If running on Desktop, start in a phone sized window."));
    parser.addOption(phoneViewOption);
    QCommandLineOption tabletViewOption(QStringList() << QLatin1String("t") << QLatin1String("tablet"), QGuiApplication::translate("main",
        "If running on Desktop, start in a tablet sized window."));
    parser.addOption(tabletViewOption);
    QCommandLineOption qmlImportOption(QStringList() << QLatin1String("I") << QLatin1String("import"), QGuiApplication::translate("main",
        "Give a path for an additional QML import directory. May be used multiple times."), QGuiApplication::translate("main", "PATH"), "");
    parser.addOption(qmlImportOption);
    QCommandLineOption testabilityOption(QLatin1String("testability"), QGuiApplication::translate("main",
        "DO NOT USE: autopilot sets this automatically"));
    parser.addOption(testabilityOption);
    parser.process(a);

    // parse any additional qml import directories
    QStringList qmlImports (parser.values(qmlImportOption));
    Q_FOREACH (const QString &import, qmlImports) {
        QString addedPath (import);
        if (addedPath.startsWith('.')) {
            addedPath = addedPath.right(addedPath.length() - 1);
            addedPath.prepend(QDir::currentPath());
        }
        importPathList.append(addedPath);
    }

    if (parser.isSet(testabilityOption) || getenv("QT_LOAD_TESTABILITY")) {
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
    if (parser.isSet(tabletViewOption)) {
        qDebug() << "running in tablet mode";
        view.engine()->rootContext()->setContextProperty("tablet", QVariant(true));
    } else if (parser.isSet(phoneViewOption)){
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
    AccountPreference preferences;
    view.engine()->rootContext()->setContextProperty("accountPreference", &preferences);

    // only search for reminders.qml relative to our binary and avoid passing
    // around relative paths for autopilot
    QString qmlFile;
    const QString filePath = QLatin1String("qml/reminders.qml");
    QStringList paths = QStandardPaths::standardLocations(QStandardPaths::DataLocation);
    paths.prepend(QCoreApplication::applicationDirPath());
    Q_FOREACH (const QString &path, paths) {
        QString myPath = path + QLatin1Char('/') + filePath;
        if (QFile::exists(myPath)) {
            qmlFile = myPath;
            break;
        }
    }
    // sanity check
    if (qmlFile.isEmpty()) {
        qFatal("File: %s does not exist at any of the standard paths!", qPrintable(filePath));
    }
    qDebug() << "using main qml file from:" << qmlFile;
    view.setSource(QUrl::fromLocalFile(qmlFile));
    view.show();

    return a.exec();
}
