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

#include "preferences.h"
#include "formattinghelper.h"

#include <QtGui/QGuiApplication>
#include <QtQuick/QQuickView>
#include <QtQml/QtQml>
#include <QLibrary>
#include <QCommandLineParser>
#include <QCommandLineOption>
#include <QDebug>
#include <QLoggingCategory>

QHash<QString, bool> s_loggingFilters;
QLoggingCategory dcApplication("Application");

void loggingCategoryFilter(QLoggingCategory *category)
{
    if (s_loggingFilters.contains(category->categoryName())) {
        bool debugEnabled = s_loggingFilters.value(category->categoryName());
        category->setEnabled(QtDebugMsg, debugEnabled);
        category->setEnabled(QtWarningMsg, debugEnabled || s_loggingFilters.value("Warnings"));
    } else {
        category->setEnabled(QtDebugMsg, false);
        category->setEnabled(QtWarningMsg, s_loggingFilters.value("qml") || s_loggingFilters.value("Warnings"));
    }
}

int main(int argc, char *argv[])
{
    QGuiApplication a(argc, argv);
    QQuickView view;
    view.setResizeMode(QQuickView::SizeRootObjectToView);

    s_loggingFilters.insert("Warnings", true);
    s_loggingFilters.insert("Application", true);
    s_loggingFilters.insert("NotesStore", true);
    s_loggingFilters.insert("JobQueue", true);
    s_loggingFilters.insert("Sync", true);
    s_loggingFilters.insert("Connection", true);
    s_loggingFilters.insert("Enml", false);
    s_loggingFilters.insert("Organizer", false);
    s_loggingFilters.insert("qml", true);

    // Set up import paths
    QStringList importPathList = view.engine()->importPathList();
    // Prepend the location of the plugin in the build dir,
    // so that Qt Creator finds it there, thus overriding the one installed
    // in the sistem if there is one
    importPathList.prepend(QCoreApplication::applicationDirPath() + "/../plugin/");

    QCommandLineParser cmdLineParser;
    cmdLineParser.setSingleDashWordOptionMode(QCommandLineParser::ParseAsLongOptions);
    QCommandLineOption phoneFactorOption(QStringList() << "p" << "phone", "If running on Desktop, start in a phone sized window.");
    cmdLineParser.addOption(phoneFactorOption);
    QCommandLineOption tabletFactorOption(QStringList() << "t" << "tablet", "If running on Desktop, start in a tablet sized window.");
    cmdLineParser.addOption(tabletFactorOption);
    QCommandLineOption importPathOption("I", "Give a path for an additional QML import directory. May be used multiple times.", "paths");
    cmdLineParser.addOption(importPathOption);
    QCommandLineOption sandboxOption(QStringList() << "s" << "sandbox", "Use sandbox.evernote.com instead of www.evernote.com.");
    cmdLineParser.addOption(sandboxOption);
    QString debugDescription = QString("Debug categories to enable. Prefix with \"No\" to disable. Warnings from all categories will be printed unless explicitly muted with \"NoWarnings\". May be used multiple times. Categories are:");
    foreach (const QString &filterName, s_loggingFilters.keys()) {
        debugDescription += "\n" + filterName + " (" + (s_loggingFilters.value(filterName) ? "yes" : "no") + ")";
    }
    QCommandLineOption debugOption(QStringList() << "d" << "debug", debugDescription, "debugAreas");
    cmdLineParser.addOption(debugOption);
    QCommandLineOption testabilityOption("testability", "Load the testability driver.");
    cmdLineParser.addOption(testabilityOption);
    cmdLineParser.addPositionalArgument("uri", "Uri to start the application in a specific mode. E.g. evernote://newnote to directly create and edit a new note.");
    cmdLineParser.addHelpOption();

    cmdLineParser.process(a);

    foreach (QString debugArea, cmdLineParser.values(debugOption)) {
        bool enable = !debugArea.startsWith("No");
        debugArea.remove(QRegExp("^No"));
        if (s_loggingFilters.contains(debugArea)) {
            s_loggingFilters[debugArea] = enable;
        }
    }
    QLoggingCategory::installFilter(loggingCategoryFilter);

    foreach (QString addedPath, cmdLineParser.values(importPathOption)) {
        if (addedPath == "." || addedPath.startsWith("./")) {
            addedPath = addedPath.right(addedPath.length() - 1);
            addedPath.prepend(QDir::currentPath());
        }
        importPathList.append(addedPath);
    }

    if (cmdLineParser.isSet(testabilityOption) || getenv("QT_LOAD_TESTABILITY")) {
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

    if (cmdLineParser.isSet(sandboxOption)) {
        view.engine()->rootContext()->setContextProperty("useSandbox", QVariant(true));
        qCDebug(dcApplication) << "Running against the sandbox server";
    } else {
        view.engine()->rootContext()->setContextProperty("useSandbox", QVariant(false));
        qCDebug(dcApplication) << "Running against the production server";
    }

    view.engine()->rootContext()->setContextProperty("tablet", QVariant(false));
    view.engine()->rootContext()->setContextProperty("phone", QVariant(false));

    if (cmdLineParser.isSet(tabletFactorOption)) {
        qCDebug(dcApplication) << "Running in tablet mode";
        view.engine()->rootContext()->setContextProperty("tablet", QVariant(true));
    } else if (cmdLineParser.isSet(phoneFactorOption)){
        qCDebug(dcApplication) << "Running in phone mode";
        view.engine()->rootContext()->setContextProperty("phone", QVariant(true));
    } else if (qgetenv("QT_QPA_PLATFORM") != "ubuntumirclient") {
        // Default to tablet size on X11
        view.engine()->rootContext()->setContextProperty("tablet", QVariant(true));
    }

    view.engine()->setImportPathList(importPathList);

    view.engine()->rootContext()->setContextProperty("uriArgs", cmdLineParser.positionalArguments());

    // Set up account preferences
    Preferences preferences;
    view.engine()->rootContext()->setContextProperty("preferences", &preferences);

    // Register FormattingHelper
    qmlRegisterType<FormattingHelper>("reminders", 1, 0, "FormattingHelper");

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

    qCDebug(dcApplication) << "Using main qml file from:" << qmlfile;
    view.setSource(QUrl::fromLocalFile(qmlfile));
    view.show();

    return a.exec();
}
