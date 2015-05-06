/*
 * Copyright (C) 2015 Canonical, Ltd.
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

#include "serverpropertysynchroniser.h"

#include <QQmlProperty>
#include <QTimer>
#include <QDebug>

ServerPropertySynchroniser::ServerPropertySynchroniser(QObject* parent)
    : QObject(parent)
    , m_serverTarget(nullptr)
    , m_userTarget(nullptr)
    , m_classComplete(false)
    , m_busy(false)
    , m_connectedServerTarget(nullptr)
    , m_connectedUserTarget(nullptr)
    , m_serverSyncTimer(new QTimer(this))
    , m_bufferDamper(nullptr)
    , m_useWaitBuffer(true)
    , m_haveNextActivate(false)
    , m_bufferedSyncTimeout(false)
    , m_serverUpdatedDuringBufferDamping(false)
    , m_activateCount(0)
{
    m_serverSyncTimer->setSingleShot(true);
    m_serverSyncTimer->setInterval(30000);
    connect(m_serverSyncTimer, &QTimer::timeout, this, &ServerPropertySynchroniser::serverSyncTimedOut);
}

void ServerPropertySynchroniser::classBegin()
{
    m_classComplete = false;
}

void ServerPropertySynchroniser::componentComplete()
{
    m_classComplete = true;
    connectServer();
    connectUser();
}

void ServerPropertySynchroniser::reset()
{
    if (m_serverSyncTimer->isActive()) {
        m_serverSyncTimer->stop();
        Q_EMIT syncWaitingChanged(false);
    }
    if (m_bufferDamper) m_bufferDamper->stop();
    m_haveNextActivate = false;
    m_activateCount = 0;
    m_serverUpdatedDuringBufferDamping = false;
}

QObject *ServerPropertySynchroniser::serverTarget() const
{
    return m_serverTarget;
}

void ServerPropertySynchroniser::setServerTarget(QObject *target)
{
    if (m_serverTarget != target) {
        m_serverTarget = target;
        Q_EMIT serverTargetChanged(m_serverTarget);

        connectServer();
    }
}

QString ServerPropertySynchroniser::serverProperty() const
{
    return m_serverProperty;
}

void ServerPropertySynchroniser::setServerProperty(const QString &property)
{
    if (m_serverProperty != property) {
        m_serverProperty = property;
        Q_EMIT serverPropertyChanged(m_serverProperty);

        connectServer();
    }
}

QObject *ServerPropertySynchroniser::userTarget() const
{
    return m_userTarget;
}

void ServerPropertySynchroniser::setUserTarget(QObject *target)
{
    if (m_userTarget != target) {
        m_userTarget = target;
        Q_EMIT userTargetChanged(m_userTarget);

        connectUser();
    }
}

QString ServerPropertySynchroniser::userProperty() const
{
    return m_userProperty;
}

void ServerPropertySynchroniser::setUserProperty(const QString &property)
{
    if (m_userProperty != property) {
        m_userProperty = property;
        Q_EMIT userPropertyChanged(m_userProperty);

        connectUser();
    }
}

QString ServerPropertySynchroniser::userTrigger() const
{
    return m_userTrigger;
}

void ServerPropertySynchroniser::setUserTrigger(const QString &trigger)
{
    if (m_userTrigger != trigger) {
        m_userTrigger = trigger;
        Q_EMIT userPropertyChanged(m_userTrigger);

        connectUser();
    }
}

int ServerPropertySynchroniser::syncTimeout() const
{
    return m_serverSyncTimer->interval();
}

void ServerPropertySynchroniser::setSyncTimeout(int timeout)
{
    if (m_serverSyncTimer->interval() != timeout) {
        m_serverSyncTimer->setInterval(timeout);
        Q_EMIT syncTimeoutChanged(timeout);
    }
}

bool ServerPropertySynchroniser::useWaitBuffer() const
{
    return m_useWaitBuffer;
}

void ServerPropertySynchroniser::setUseWaitBuffer(bool value)
{
    if (m_useWaitBuffer != value) {
        m_useWaitBuffer = value;
        Q_EMIT useWaitBufferChanged(m_useWaitBuffer);
    }
}

int ServerPropertySynchroniser::maximumWaitBufferInterval() const
{
    return m_bufferDamper ? m_bufferDamper->interval() : -1;
}

void ServerPropertySynchroniser::setMaximumWaitBufferInterval(int timeout)
{
    if (timeout >= 0) {
        if (!m_bufferDamper) {
            m_bufferDamper = new QTimer(this);
            m_bufferDamper->setInterval(timeout);
            m_bufferDamper->setSingleShot(true);
            connect(m_bufferDamper, &QTimer::timeout, this, &ServerPropertySynchroniser::bufferTimedOut);

            Q_EMIT maximumWaitBufferIntervalChanged(timeout);
        }
        else if (timeout != m_bufferDamper->interval()) {
            m_bufferDamper->setInterval(timeout);
            Q_EMIT maximumWaitBufferIntervalChanged(timeout);
        }

    } else if (m_bufferDamper) {
        if (m_bufferDamper->isActive()) {
            m_haveNextActivate = false;
        }
        delete m_bufferDamper;
        m_bufferDamper = nullptr;
        Q_EMIT maximumWaitBufferIntervalChanged(timeout);
    }
}

bool ServerPropertySynchroniser::bufferedSyncTimeout() const
{
    return m_bufferedSyncTimeout;
}

void ServerPropertySynchroniser::setBufferedSyncTimeout(bool value)
{
    if (m_bufferedSyncTimeout != value) {
        m_bufferedSyncTimeout = value;
        Q_EMIT bufferedSyncTimeoutChanged(value);
    }
}

bool ServerPropertySynchroniser::syncWaiting() const
{
    return m_serverSyncTimer->isActive();
}

void ServerPropertySynchroniser::activate()
{
    // Don't want any signals we fire to create binding loops.
    if (m_busy) return;
    m_busy = true;

    if (m_useWaitBuffer) {
        // Dampen the activations? Buffer the change.
        if (m_bufferDamper) {
            if (m_bufferDamper->isActive()) {
                m_haveNextActivate = true;
                m_busy = false;
                return;
            }
            m_bufferDamper->start();
        // Not using a damp interval? Buffer the change till we get a server response, or timeout
        } else if (m_serverSyncTimer->isActive()) {
            m_haveNextActivate = true;
            m_busy = false;
            return;
        }
    }

    m_serverSyncTimer->start();
    Q_EMIT syncWaitingChanged(true);
    m_activateCount++;

    // Fire off a change to the server user property value
    QQmlProperty userProp(m_userTarget, m_userProperty);
    if (!userProp.isValid()) {
        Q_EMIT syncTriggered(QVariant());
    } else {
        Q_EMIT syncTriggered(userProp.read());
    }
    m_busy = false;
}

void ServerPropertySynchroniser::connectServer()
{
    // if we havent finished constructing the class, then wait
    if (!m_classComplete) return;
    reset();

    if (m_connectedServerTarget) QObject::disconnect(m_connectedServerTarget, 0, this, 0);
    if (!m_serverTarget || m_serverProperty.isEmpty()) {
        return;
    }

    // Connect to the server property change
    QQmlProperty prop(m_serverTarget, m_serverProperty);
    if (prop.isValid()) {
        if (prop.connectNotifySignal(this, SLOT(updateUserValue()))) {
            m_connectedServerTarget = m_serverTarget;
        }
        // once we're connected to the server property, we need to make sure the user target is
        // set to the server value
        updateUserValue();
    }
}

void ServerPropertySynchroniser::connectUser()
{
    // if we havent finished constructing the class, then wait
    if (!m_classComplete) return;
    reset();

    if (m_connectedUserTarget) QObject::disconnect(m_connectedUserTarget, 0, this, 0);
    if (!m_userTarget) {
        if (!parent()) return;
        m_userTarget = parent();
        Q_EMIT userTargetChanged(m_userTarget);
    }

    if (m_userTrigger.isEmpty()) {
        // Connect to the user property change
        QQmlProperty prop(m_userTarget, m_userProperty);
        if (prop.isValid()) {
            if (prop.connectNotifySignal(this, SLOT(activate()))) {
                m_connectedUserTarget = m_userTarget;
            }
            // once we're connected to the user property, we need to make sure the user target is
            // set to the server value
            updateUserValue();
        }
    } else {
        QQmlProperty prop(m_userTarget, m_userTrigger);
        if (prop.isValid() && prop.isSignalProperty()) {
            if (connect(m_userTarget, ("2" + prop.method().methodSignature()).constData(),
                        this, SLOT(activate()))) {
                m_connectedUserTarget = m_userTarget;
            }

            // once we're connected to the user signal, we need to make sure the user target is
            // set to the server value
            updateUserValue();
        }
    }
}

void ServerPropertySynchroniser::updateUserValue()
{
    // Don't want any signals we fire to create binding loops.
    if (m_busy) return;
    m_busy = true;

    // Are we waiting for a server sync.
    if (m_serverSyncTimer->isActive()) {
        // are we waiting for more from the server? (number of activates sent > number of receives)
        if (--m_activateCount > 0) {
            // ignore the change and update on server sync timeout.
            m_busy = false;
            return;
        }

        // stop the wait
        m_serverSyncTimer->stop();
        Q_EMIT syncWaitingChanged(false);
    }
    m_activateCount = 0;
    m_serverUpdatedDuringBufferDamping = m_bufferDamper && m_bufferDamper->isActive();

    QQmlProperty userProp(m_userTarget, m_userProperty);
    QQmlProperty serverProp(m_serverTarget, m_serverProperty);
    if (!userProp.isValid() || !serverProp.isValid()) {
        m_busy = false;
        return;
    }

    // If we've been buffering changes since last change was send,
    // we verify that what the server gave us is what we want, and send another
    // activation if not.
    if (m_haveNextActivate) {
        m_haveNextActivate = false;
        m_busy = false;
        if (serverProp.read() != userProp.read()) {
            activate();
        }
        return;
    }

    // Don't update until we hit the buffer timeout.
    if (m_serverUpdatedDuringBufferDamping) {
        m_busy = false;
        return;
    }

    // update the user target property.
    userProp.write(serverProp.read());
    m_busy = false;
}

void ServerPropertySynchroniser::serverSyncTimedOut()
{
    if (m_haveNextActivate && !m_bufferedSyncTimeout) {
        m_haveNextActivate = false;
    }
    Q_EMIT syncWaitingChanged(false);
    updateUserValue();
}

void ServerPropertySynchroniser::bufferTimedOut()
{
    if (m_haveNextActivate) {
        m_haveNextActivate = false;
        activate();
    }
    // if we received a server change while we were in change buffer but don't need to send another activate,
    // update to the value we received.
    else if (m_serverUpdatedDuringBufferDamping) {
        // Update the user value.
        if (m_busy) return;
        m_busy = true;

        QQmlProperty userProp(m_userTarget, m_userProperty);
        QQmlProperty serverProp(m_serverTarget, m_serverProperty);
        if (!userProp.isValid() || !serverProp.isValid()) {
            m_busy = false;
            return;
        }
        userProp.write(serverProp.read());
        m_busy = false;
    }
    m_serverUpdatedDuringBufferDamping = false;
}
