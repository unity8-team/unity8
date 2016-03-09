/*
 * Copyright (C) 2016 Canonical, Ltd.
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

#include "plugin.h"
#include "aethercastmanager.h"

#include <QtQml/qqml.h>
#include <QDebug>

static QObject *manager_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    qDebug() << "imageprovider is" << engine->imageProvider("cursor");
    return new AethercastManager();
}

void AethercastPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("Aethercast"));
    qmlRegisterSingletonType<AethercastManager>(uri, 0, 1, "AethercastManager", manager_provider);
}
