/*
 * Copyright 2014 Canonical Ltd.
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
 *
 * Authors:
 *      Michael Zanetti <michael.zanetti@canonical.com>
 */

#include "dbusinterface.h"
#include "launchermodel.h"
#include "launcheritem.h"

#include <QDBusArgument>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDebug>
#include <ubuntu-app-launch/appid.h>

namespace ual = ubuntu::app_launch;

DBusInterface::DBusInterface(LauncherModel *parent):
    UnityDBusVirtualObject(QStringLiteral("/com/canonical/Unity/Launcher"), QStringLiteral("com.canonical.Unity.Launcher"), true, parent),
    m_launcherModel(parent)
{
}

QString DBusInterface::introspect(const QString &path) const
{
    /* This case we should just list the nodes */
    if (path == QLatin1String("/com/canonical/Unity/Launcher/") || path == QLatin1String("/com/canonical/Unity/Launcher")) {
        QString nodes;

        // Add Refresh to introspect
        nodes = QStringLiteral("<interface name=\"com.canonical.Unity.Launcher\">"
                "<method name=\"Refresh\"/>"
                "</interface>");

        // Add dynamic properties for launcher emblems
        for (int i = 0; i < m_launcherModel->rowCount(); i++) {
            auto ualappid = ual::AppID::find(m_launcherModel->get(i)->appId().toStdString());
            nodes.append("<node name=\"");
            nodes.append(QString::fromStdString(ualappid.dbusID()));
            nodes.append("\"/>\n");
        }
        return nodes;
    }

    /* Should not happen, but let's handle it */
    if (!path.startsWith(QLatin1String("/com/canonical/Unity/Launcher"))) {
        return QLatin1String("");
    }

    /* Now we should be looking at a node */
    QString nodeiface =
        QStringLiteral("<interface name=\"com.canonical.Unity.Launcher.Item\">"
            "<property name=\"count\" type=\"i\" access=\"readwrite\" />"
            "<property name=\"countVisible\" type=\"b\" access=\"readwrite\" />"
            "<property name=\"progress\" type=\"i\" access=\"readwrite\" />"
            "<method name=\"Alert\" />"
        "</interface>");
    return nodeiface;
}

bool DBusInterface::handleMessage(const QDBusMessage& message, const QDBusConnection& connection)
{
    /* Check to make sure we're getting properties on our interface */
    if (message.type() != QDBusMessage::MessageType::MethodCallMessage) {
        return false;
    }

    /* Break down the path to just the app id */
    bool validpath = true;
    QString pathtemp = message.path();
    if (!pathtemp.startsWith(QLatin1String("/com/canonical/Unity/Launcher/"))) {
        validpath = false;
    }
    pathtemp.remove(QStringLiteral("/com/canonical/Unity/Launcher/"));
    if (pathtemp.indexOf('/') >= 0) {
        validpath = false;
    }

    /* Find ourselves an appid */
    auto ualappid = ual::AppID::parseDBusID(pathtemp.toStdString());
    auto appid = QString::fromStdString(ualappid.persistentID());

    // First handle methods of the Launcher interface
    if (message.interface() == QLatin1String("com.canonical.Unity.Launcher")) {
        if (message.member() == QLatin1String("Refresh")) {
            QDBusMessage reply = message.createReply();
            Q_EMIT refreshCalled();
            return connection.send(reply);
        }
    } else if (message.interface() == QLatin1String("com.canonical.Unity.Launcher.Item")) {
        // Handle methods of the Launcher-Item interface
        if (message.member() == QLatin1String("Alert") && validpath) {
            QDBusMessage reply = message.createReply();
            Q_EMIT alertCalled(appid);
            return connection.send(reply);
        }
    }

    // Now handle dynamic properties (for launcher emblems)
    if (message.interface() != QLatin1String("org.freedesktop.DBus.Properties")) {
        return false;
    }

    const QList<QVariant> messageArguments = message.arguments();
    if (message.member() == QLatin1String("Get") && (messageArguments.count() != 2 || messageArguments[0].toString() != QLatin1String("com.canonical.Unity.Launcher.Item"))) {
        return false;
    }

    if (message.member() == QLatin1String("Set") && (messageArguments.count() != 3 || messageArguments[0].toString() != QLatin1String("com.canonical.Unity.Launcher.Item"))) {
        return false;
    }

    if (!validpath) {
        return false;
    }

    int index = m_launcherModel->findApplication(appid);
    LauncherItem *item = static_cast<LauncherItem*>(m_launcherModel->get(index));

    QVariantList retval;
    if (message.member() == QLatin1String("Get")) {
        QString cachedString = messageArguments[1].toString();
        if (!item) {
            return false;
        }
        if (cachedString == QLatin1String("count")) {
            retval.append(QVariant::fromValue(QDBusVariant(item->count())));
        } else if (cachedString == QLatin1String("countVisible")) {
            retval.append(QVariant::fromValue(QDBusVariant(item->countVisible())));
        } else if (cachedString == QLatin1String("progress")) {
            retval.append(QVariant::fromValue(QDBusVariant(item->progress())));
        }
    } else if (message.member() == QLatin1String("Set")) {
        QString cachedString = messageArguments[1].toString();
        if (cachedString == QLatin1String("count")) {
            int newCount = messageArguments[2].value<QDBusVariant>().variant().toInt();
            if (!item || newCount != item->count()) {
                Q_EMIT countChanged(appid, newCount);
                notifyPropertyChanged(QStringLiteral("com.canonical.Unity.Launcher.Item"), pathtemp, QStringLiteral("count"), QVariant(newCount));
            }
        } else if (cachedString == QLatin1String("countVisible")) {
            bool newVisible = messageArguments[2].value<QDBusVariant>().variant().toBool();
            if (!item || newVisible != item->countVisible()) {
                Q_EMIT countVisibleChanged(appid, newVisible);
                notifyPropertyChanged(QStringLiteral("com.canonical.Unity.Launcher.Item"), pathtemp, QStringLiteral("countVisible"), newVisible);
            }
        } else if (cachedString == QLatin1String("progress")) {
            int newProgress = messageArguments[2].value<QDBusVariant>().variant().toInt();
            if (!item || newProgress != item->progress()) {
                Q_EMIT progressChanged(appid, newProgress);
                notifyPropertyChanged(QStringLiteral("com.canonical.Unity.Launcher.Item"), pathtemp, QStringLiteral("progress"), QVariant(newProgress));
            }
        }
    } else if (message.member() == QLatin1String("GetAll")) {
        if (item) {
            QVariantMap all;
            all.insert(QStringLiteral("count"), item->count());
            all.insert(QStringLiteral("countVisible"), item->countVisible());
            all.insert(QStringLiteral("progress"), item->progress());
            retval.append(all);
        }
    } else {
        return false;
    }

    QDBusMessage reply = message.createReply(retval);
    return connection.send(reply);
}
