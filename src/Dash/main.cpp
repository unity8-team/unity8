/*
 * Copyright (C) 2014-2016 Canonical, Ltd.
 *
 * Authors:
 *  Michael Zanetti <michael.zanetti@canonical.com>
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

#include <QtQuick/QQuickView>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlEngine>
#include <QtQml/QQmlContext>
#include <QDebug>
#include <QCommandLineParser>
#include <QLibrary>
#include <libintl.h>
#include <QQmlApplicationEngine>
#include <QTranslator>
#include <QLibraryInfo>
#include <QLocale>

#include <paths.h>
#include "../qmldebuggerutils.h"
#include "../CachingNetworkManagerFactory.h"
#include "../UnixSignalHandler.h"

int main(int argc, const char *argv[])
{
    qSetMessagePattern("[%{time yyyy-MM-dd:hh:mm:ss.zzz}] %{if-category}%{category}: %{endif}%{message}");
    if (enableQmlDebugger(argc, argv)) {
        QQmlDebuggingEnabler qQmlEnableDebuggingHelper(true);
    }

    QGuiApplication *application = new QGuiApplication(argc, (char**)argv);

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Description: Unity 8 Shell Dash"));
    parser.addHelpOption();

    QCommandLineOption windowGeometryOption(QStringList() << QStringLiteral("windowgeometry"),
        QStringLiteral("Specify the window geometry as [<width>x<height>]"), QStringLiteral("windowgeometry"), QStringLiteral("1"));
    parser.addOption(windowGeometryOption);

   // FIXME Remove once we drop the need of the hint
    QCommandLineOption desktopFileHintOption(QStringLiteral("desktop_file_hint"),
        QStringLiteral("The desktop_file_hint option for QtMir"), QStringLiteral("hint_file"));
    parser.addOption(desktopFileHintOption);

    // Treat args with single dashes the same as arguments with two dashes
    // Ex: -fullscreen == --fullscreen
    parser.setSingleDashWordOptionMode(QCommandLineParser::ParseAsLongOptions);
    parser.process(*application);

    if (getenv("QT_LOAD_TESTABILITY")) {
        QLibrary testLib(QStringLiteral("qttestability"));
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

    QTranslator qtTranslator;
    if (qtTranslator.load(QLocale(), QStringLiteral("qt_"), qgetenv("SNAP"), QLibraryInfo::location(QLibraryInfo::TranslationsPath))) {
        application->installTranslator(&qtTranslator);
    }

    bindtextdomain("unity8", translationDirectory().toUtf8().data());
    textdomain("unity8");

    QQmlApplicationEngine *engine = new QQmlApplicationEngine(application);

    int initialWidth = -1;
    int initialHeight = -1;
    if (parser.isSet(windowGeometryOption) &&
        parser.value(windowGeometryOption).split('x').size() == 2)
    {
        QStringList geom = parser.value(windowGeometryOption).split('x');
        QSize windowSize(geom.at(0).toInt(), geom.at(1).toInt());
        if (windowSize.isValid()) {
            initialWidth = windowSize.width();
            initialHeight = windowSize.height();
        }
    }
    engine->rootContext()->setContextProperty("initialWidth", initialWidth);
    engine->rootContext()->setContextProperty("initialHeight", initialHeight);

    QUrl source(::qmlDirectory() + "/Dash/DashApplication.qml");
    prependImportPaths(engine, ::overrideImportPaths());
    appendImportPaths(engine, ::fallbackImportPaths());

    CachingNetworkManagerFactory *managerFactory = new CachingNetworkManagerFactory();
    engine->setNetworkAccessManagerFactory(managerFactory);

    engine->load(source);

    UnixSignalHandler signalHandler([]{
        QGuiApplication::exit(0);
    });
    signalHandler.setupUnixSignalHandlers();

    int result = application->exec();

    delete engine;

    delete application;

    return result;
}
