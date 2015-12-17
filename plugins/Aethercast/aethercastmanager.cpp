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

#include "aethercastmanager.h"
#include "managerinterface.h"
#include "inputprovider.h"

#include <QDebug>
#include <QDBusConnection>

#define MANAGER_PATH QStringLiteral("/org/aethercast/InputProvider")

AethercastManager::AethercastManager(QObject *parent):
    QObject(parent),
    m_manager(new ManagerInterface(QStringLiteral("org.aethercast"), QStringLiteral("/org/aethercast"), QDBusConnection::systemBus(), this)),
    m_inputProvider(new InputProvider(this))
{
    QDBusConnection::systemBus().registerObject(MANAGER_PATH, QStringLiteral("org.aethercast.InputProvider"), m_inputProvider);
    m_manager->RegisterInputProvider(QDBusObjectPath(MANAGER_PATH), QVariantMap());

    connect(m_inputProvider, &InputProvider::cursorChanged, this, &AethercastManager::cursorChanged);
}

AethercastManager::~AethercastManager()
{
    m_manager->UnregisterInputProvider(QDBusObjectPath(MANAGER_PATH));
}

int AethercastManager::cursorX() const
{
    return m_inputProvider->cursorY();
}

void AethercastManager::setCursorX(int cursorX)
{
    m_inputProvider->setCursorX(cursorX);
}

int AethercastManager::cursorY() const
{
    return m_inputProvider->cursorY();
}

void AethercastManager::setCursorY(int cursorY)
{
    m_inputProvider->setCursorX(cursorY)
}

QString AethercastManager::cursor() const
{
    return m_inputProvider->cursor();
}

void AethercastManager::setCursor(const QString &cursor)
{
    m_inputProvider->setCursor(cursor);
}

void AethercastManager::sendMousePosition(int x, int y)
{
    m_inputProvider->setMousePosition(x, y);
}
