/*
 * Copyright (C) 2015 Canonical, Ltd.
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

#include "ShellApplication.h"

// Qt
#include <QLibrary>
#include <QQmlContext>
#include <QScreen>

#include <libintl.h>

// libandroid-properties
#include <hybris/properties/properties.h>

// local
#include <paths.h>
#include "CachingNetworkManagerFactory.h"
#include "UnityCommandLineParser.h"

ShellApplication::ShellApplication(int & argc, char ** argv, bool isMirServer)
    : QGuiApplication(argc, argv)
{

    setApplicationName(QStringLiteral("unity8"));

    setupQmlEngine(isMirServer);

    UnityCommandLineParser parser(*this);

    if (!parser.deviceName().isEmpty()) {
        m_deviceName = parser.deviceName();
    } else {
        char buffer[200];
        property_get("ro.product.device", buffer /* value */, "desktop" /* default_value*/);
        m_deviceName = QString(buffer);
    }
    m_qmlArgs.setDeviceName(m_deviceName);

    m_qmlArgs.setMode(parser.mode());

    // The testability driver is only loaded by QApplication but not by QGuiApplication.
    // However, QApplication depends on QWidget which would add some unneeded overhead => Let's load the testability driver on our own.
    if (parser.hasTestability() || getenv("QT_LOAD_TESTABILITY")) {
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

    bindtextdomain("unity8", translationDirectory().toUtf8().data());
    textdomain("unity8");

    m_qmlEngine->rootContext()->setContextProperty(QStringLiteral("applicationArguments"), &m_qmlArgs);

    #ifdef UNITY8_ENABLE_TOUCH_EMULATION
    // You will need this if you want to interact with touch-only components using a mouse
    // Needed only when manually testing on a desktop.
    if (parser.hasMouseToTouch()) {
        m_mouseTouchAdaptor = MouseTouchAdaptor::instance();
    }
    #endif
}

ShellApplication::~ShellApplication()
{
    destroyResources();
}

void ShellApplication::destroyResources()
{
    // Deletion order is important. Don't use QScopedPointers and the like
    // Otherwise the process will hang on shutdown (bug somewhere I guess).
    #ifdef UNITY8_ENABLE_TOUCH_EMULATION
    delete m_mouseTouchAdaptor;
    m_mouseTouchAdaptor = nullptr;
    #endif

    delete m_qmlEngine;
    m_qmlEngine = nullptr;
}

void ShellApplication::setupQmlEngine(bool isMirServer)
{
    m_qmlEngine = new QQmlApplicationEngine(::qmlDirectory() + "/main.qml", this);

    m_qmlEngine->setBaseUrl(QUrl::fromLocalFile(::qmlDirectory()));

    prependImportPaths(m_qmlEngine, ::overrideImportPaths());
    if (!isMirServer) {
        prependImportPaths(m_qmlEngine, ::nonMirImportPaths());
    }
    appendImportPaths(m_qmlEngine, ::fallbackImportPaths());

    m_qmlEngine->setNetworkAccessManagerFactory(new CachingNetworkManagerFactory);

    QObject::connect(m_qmlEngine, &QQmlEngine::quit, this, &QGuiApplication::quit);
}
