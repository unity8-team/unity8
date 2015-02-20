/*
 * Copyright (C) 2012,2013 Canonical, Ltd.
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
 *
 * Authors: Gerry Boland <gerry.boland@canonical.com>
 *          Michael Terry <michael.terry@canonical.com>
 */

#include "plugin.h"
#include "DBusGreeter.h"
#include "DBusGreeterList.h"
#include "Greeter.h"
#include "UsersModel.h"
#include <libusermetricsoutput/ColorTheme.h>
#include <libusermetricsoutput/UserMetrics.h>
#include <QLightDM/UsersModel>

#include <QAbstractItemModel>
#include <QDBusConnection>
#include <QQmlContext>
#include <QtQml/qqml.h>
#include <dlfcn.h>

static QObject *greeter_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    Greeter *greeter = new Greeter();
    new DBusGreeter(greeter, "/");
    new DBusGreeterList(greeter, "/list");

    return greeter;
}

static QObject *users_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return new UsersModel();
}

static QObject *infographic_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return UserMetricsOutput::UserMetrics::getInstance();
}

LightDMPlugin::LightDMPlugin()
    : QQmlExtensionPlugin(),
      libHandle(NULL)
{
}

LightDMPlugin::~LightDMPlugin()
{
    if (libHandle) {
        dlclose(libHandle);
    }
}

void LightDMPlugin::initializeEngine(QQmlEngine *engine, const char * uri)
{
    Q_ASSERT(uri == QLatin1String("LightDM"));

    if (engine->rootContext()->contextProperty("shellMode").toString() != "greeter") {
        // Use our own internal version that authenticates against PAM directly
        libHandle = dlopen(SHELL_INSTALL_QML "/liblightdm/liblightdm-qt5-3.so", RTLD_LAZY);
    }
}

void LightDMPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("LightDM"));

    qmlRegisterType<QAbstractItemModel>();
    qmlRegisterType<UserMetricsOutput::ColorTheme>();
    qRegisterMetaType<QLightDM::Greeter::MessageType>("QLightDM::Greeter::MessageType");
    qRegisterMetaType<QLightDM::Greeter::PromptType>("QLightDM::Greeter::PromptType");
    qmlRegisterSingletonType<Greeter>(uri, 0, 1, "Greeter", greeter_provider);
    qmlRegisterSingletonType<UsersModel>(uri, 0, 1, "Users", users_provider);
    qmlRegisterUncreatableType<QLightDM::UsersModel>(uri, 0, 1, "UserRoles", "Type is not instantiable");
    qmlRegisterSingletonType<UserMetricsOutput::UserMetrics>(uri, 0, 1, "Infographic", infographic_provider);
}
