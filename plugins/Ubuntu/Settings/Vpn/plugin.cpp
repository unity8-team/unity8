/*
 * Copyright (C) 2016 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// local
#include "plugin.h"
#include "ubuntusettingsvpn.h"

// Qt
#include <QtQml/qqml.h>

static QObject *ubuntuSettingsVpnSingeltonProvider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    UbuntuSettingsVpn *vpn = new UbuntuSettingsVpn();
    return vpn;
}

void UbuntuSettingsVpnPlugin::registerTypes(const char *uri)
{
    qmlRegisterSingletonType<UbuntuSettingsVpn>(uri, 0, 1, "UbuntuSettingsVpn", ubuntuSettingsVpnSingeltonProvider);
}
