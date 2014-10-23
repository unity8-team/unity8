/*
 * Copyright (C) 2014 Canonical, Ltd.
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

#include "signalbinder.h"

#include <QQmlProperty>
#include <QDebug>

SignalBinder::SignalBinder(QObject* parent)
    : QObject(parent)
    , m_serverTarget(nullptr)
    , m_clientTarget(nullptr)
    , m_bidirectional(false)
    , m_classComplete(false)
    , m_busy(false)
    , m_connectedServerTarget(nullptr)
    , m_connectedClientTarget(nullptr)
{
}

void SignalBinder::classBegin()
{
    m_classComplete = false;
}

void SignalBinder::componentComplete()
{
    m_classComplete = true;
    connectServer();
    connectClient();
}

QObject *SignalBinder::serverTarget() const
{
    return m_serverTarget;
}

void SignalBinder::setServerTarget(QObject *target)
{
    if (m_serverTarget != target) {
        m_serverTarget = target;
        Q_EMIT serverTargetChanged(m_serverTarget);

        connectServer();
    }
}

QString SignalBinder::serverProperty() const
{
    return m_serverProperty;
}

void SignalBinder::setServerProperty(const QString &property)
{
    if (m_serverProperty != property) {
        m_serverProperty = property;
        Q_EMIT serverPropertyChanged(m_serverProperty);

        connectServer();
    }
}

QObject *SignalBinder::clientTarget() const
{
    return m_clientTarget;
}

void SignalBinder::setClientTarget(QObject *target)
{
    if (m_clientTarget != target) {
        m_clientTarget = target;
        Q_EMIT clientTargetChanged(m_clientTarget);

        connectClient();
    }
}

QString SignalBinder::clientProperty() const
{
    return m_clientProperty;
}

void SignalBinder::setClientProperty(const QString &property)
{
    if (m_clientProperty != property) {
        m_clientProperty = property;
        Q_EMIT clientPropertyChanged(m_clientProperty);

        connectClient();
    }
}

bool SignalBinder::bidirectional() const
{
    return m_bidirectional;
}

void SignalBinder::setBidirectional(bool bidirectional)
{
    if (m_bidirectional != bidirectional) {

        m_bidirectional = bidirectional;
        Q_EMIT bidirectionalChanged(m_bidirectional);

        connectClient();
    }
}

void SignalBinder::connectServer()
{
    if (m_connectedServerTarget) QObject::disconnect(m_connectedServerTarget, 0, this, 0);

    if (!m_classComplete) return;
    if (!m_serverTarget || m_serverProperty.isEmpty()) {
        return;
    }
    QQmlProperty prop(m_serverTarget, m_serverProperty);
    if (prop.isValid()) {
        if (prop.connectNotifySignal(this, SLOT(updateClientValue()))) {
            m_connectedServerTarget = m_serverTarget;
        }
        updateClientValue();
    }
}

void SignalBinder::connectClient()
{
    if (m_connectedClientTarget) QObject::disconnect(m_connectedClientTarget, 0, this, 0);

    if (!m_classComplete) return;
    if (!m_bidirectional || !m_clientTarget || m_clientProperty.isEmpty()) {
        return;
    }
    QQmlProperty prop(m_clientTarget, m_clientProperty);
    if (prop.isValid()) {
        if (prop.connectNotifySignal(this, SLOT(updateServerValue()))) {
            m_connectedClientTarget = m_clientTarget;
        }
        updateClientValue();
    }
}

void SignalBinder::updateClientValue()
{
    if (m_busy) return;
    m_busy = true;

    QQmlProperty clientProp(m_clientTarget, m_clientProperty);
    QQmlProperty serverProp(m_serverTarget, m_serverProperty);
    if (!clientProp.isValid() || !serverProp.isValid()) return;

    clientProp.write(serverProp.read());
    m_busy = false;
}

void SignalBinder::updateServerValue()
{
    if (m_busy) return;
    m_busy = true;

    QQmlProperty clientProp(m_clientTarget, m_clientProperty);
    QQmlProperty serverProp(m_serverTarget, m_serverProperty);
    if (!clientProp.isValid() || !serverProp.isValid()) return;

    serverProp.write(clientProp.read());
    m_busy = false;
}
