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

#include "serveractivationsync.h"

#include <QQmlProperty>
#include <QTimer>

ServerActivationSync::ServerActivationSync(QObject* parent)
    : QObject(parent)
    , m_serverTarget(nullptr)
    , m_userTarget(nullptr)
    , m_classComplete(false)
    , m_busy(false)
    , m_connectedServerTarget(nullptr)
    , m_serverSync(new QTimer(this))
    , m_useWaitBuffer(true)
    , m_buffering(false)
    , m_bufferedSyncTimeout(false)
{
    m_serverSync->setSingleShot(true);
    m_serverSync->setInterval(30000);
    connect(m_serverSync, &QTimer::timeout, this, &ServerActivationSync::serverSyncTimedOut);
}

void ServerActivationSync::classBegin()
{
    m_classComplete = false;
}

void ServerActivationSync::componentComplete()
{
    m_classComplete = true;
    connectServer();
}

QObject *ServerActivationSync::serverTarget() const
{
    return m_serverTarget;
}

void ServerActivationSync::setServerTarget(QObject *target)
{
    if (m_serverTarget != target) {
        m_serverTarget = target;
        Q_EMIT serverTargetChanged(m_serverTarget);

        connectServer();
    }
}

QString ServerActivationSync::serverProperty() const
{
    return m_serverProperty;
}

void ServerActivationSync::setServerProperty(const QString &property)
{
    if (m_serverProperty != property) {
        m_serverProperty = property;
        Q_EMIT serverPropertyChanged(m_serverProperty);

        connectServer();
    }
}

QObject *ServerActivationSync::userTarget() const
{
    return m_userTarget;
}

void ServerActivationSync::setUserTarget(QObject *target)
{
    if (m_userTarget != target) {
        m_userTarget = target;
        Q_EMIT userTargetChanged(m_userTarget);
    }
}

QString ServerActivationSync::userProperty() const
{
    return m_userProperty;
}

void ServerActivationSync::setUserProperty(const QString &property)
{
    if (m_userProperty != property) {
        m_userProperty = property;
        Q_EMIT userPropertyChanged(m_userProperty);
    }
}

int ServerActivationSync::syncTimeout() const
{
    return m_serverSync->interval();
}

void ServerActivationSync::setSyncTimeout(int timeout)
{
    if (m_serverSync->interval() != timeout) {
        m_serverSync->setInterval(timeout);
        Q_EMIT syncTimeoutChanged(timeout);
    }
}

bool ServerActivationSync::useWaitBuffer() const
{
    return m_useWaitBuffer;
}

void ServerActivationSync::setUseWaitBuffer(bool value)
{
    if (m_useWaitBuffer != value) {
        m_useWaitBuffer = value;
        Q_EMIT useWaitBufferChanged(m_useWaitBuffer);
    }
}

bool ServerActivationSync::bufferedSyncTimeout() const
{
    return m_bufferedSyncTimeout;
}

void ServerActivationSync::setBufferedSyncTimeout(bool value)
{
    if (m_bufferedSyncTimeout != value) {
        m_bufferedSyncTimeout = value;
        Q_EMIT bufferedSyncTimeoutChanged(value);
    }
}

bool ServerActivationSync::syncWaiting() const
{
    return m_serverSync->isActive();
}

void ServerActivationSync::activate()
{
    if (m_busy) return;
    m_busy = true;

    // Still waiting for an update from server? Buffer the change.
    if (m_serverSync->isActive()) {
        m_busy = false;
        m_buffering = m_useWaitBuffer;
        return;
    }

    m_serverSync->start();
    Q_EMIT syncWaitingChanged(true);

    QQmlProperty userProp(m_userTarget, m_userProperty);
    if (!userProp.isValid()) {
        Q_EMIT activated(QVariant());
    } else {
        Q_EMIT activated(userProp.read());
    }
    m_busy = false;
}

void ServerActivationSync::connectServer()
{
    if (m_connectedServerTarget) QObject::disconnect(m_connectedServerTarget, 0, this, 0);

    if (!m_classComplete) return;
    if (!m_serverTarget || m_serverProperty.isEmpty()) {
        return;
    }
    QQmlProperty prop(m_serverTarget, m_serverProperty);
    if (prop.isValid()) {
        if (prop.connectNotifySignal(this, SLOT(updateUserValue()))) {
            m_connectedServerTarget = m_serverTarget;
        }
        updateUserValue();
    }
}

void ServerActivationSync::updateUserValue()
{
    if (m_busy) return;
    m_busy = true;

    if (m_serverSync->isActive()) {
        m_serverSync->stop();
        Q_EMIT syncWaitingChanged(false);
    }

    QQmlProperty userProp(m_userTarget, m_userProperty);
    QQmlProperty serverProp(m_serverTarget, m_serverProperty);
    if (!userProp.isValid() || !serverProp.isValid()) {
        m_busy = false;
        return;
    }

    // If we've been buffering changes since last change was send,
    // we verify that what the server gave us is what we want, and send another
    // activation if not.
    if (m_buffering) {
        m_buffering = false;
        m_busy = false;
        if (serverProp.read() != userProp.read()) {
            activate();
        }
        return;
    }

    userProp.write(serverProp.read());
    m_busy = false;
}

void ServerActivationSync::serverSyncTimedOut()
{
    if (m_buffering && !m_bufferedSyncTimeout) {
        m_buffering = false;
    }
    Q_EMIT syncWaitingChanged(false);
    updateUserValue();
}
