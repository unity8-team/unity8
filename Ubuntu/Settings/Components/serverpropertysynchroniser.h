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

#ifndef SERVERPROPERTYSYNCHRONISER_H
#define SERVERPROPERTYSYNCHRONISER_H

#include <QObject>
#include <QQmlParserStatus>
#include <QVariant>

class QTimer;

class ServerPropertySynchroniser : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)

    // Target object which contains the property to keep the user property in sync with.
    Q_PROPERTY(QObject* serverTarget READ serverTarget WRITE setServerTarget NOTIFY serverTargetChanged)
    // Server property to keep the user property in sync with.
    Q_PROPERTY(QString serverProperty READ serverProperty WRITE setServerProperty NOTIFY serverPropertyChanged)

    // User object (control) which sources the property to update the server property.
    // Defaults to the object's parent if not set.
    Q_PROPERTY(QObject* userTarget READ userTarget WRITE setUserTarget NOTIFY userTargetChanged)
    // User property to update the server property.
    Q_PROPERTY(QString userProperty READ userProperty WRITE setUserProperty NOTIFY userPropertyChanged)
    // Trigger that causes an update. By default, the control will use the userProperty change notification.
    // eg. "onTriggered"
    Q_PROPERTY(QString userTrigger READ userTrigger WRITE setUserTrigger NOTIFY userTriggerChanged)

    // Time to wait for a change verification before re-asserting the server value.
    Q_PROPERTY(int syncTimeout READ syncTimeout WRITE setSyncTimeout NOTIFY syncTimeoutChanged)

    // Buffer user property changes until the previous change is verified
    Q_PROPERTY(bool useWaitBuffer
               READ useWaitBuffer
               WRITE setUseWaitBuffer
               NOTIFY useWaitBufferChanged)

    // Resend the buffered value if we timeout waiting for a change from the server
    Q_PROPERTY(bool bufferedSyncTimeout
               READ bufferedSyncTimeout
               WRITE setBufferedSyncTimeout
               NOTIFY bufferedSyncTimeoutChanged)

    // True if we're waiting for a change verification from the server
    Q_PROPERTY(bool syncWaiting READ syncWaiting NOTIFY syncWaitingChanged)

public:
    ServerPropertySynchroniser(QObject* parent = nullptr);

    QObject* serverTarget() const;
    void setServerTarget(QObject* target);

    QString serverProperty() const;
    void setServerProperty(const QString& property);

    QObject* userTarget() const;
    void setUserTarget(QObject* target);

    QString userProperty() const;
    void setUserProperty(const QString& property);

    QString userTrigger() const;
    void setUserTrigger(const QString& trigger);

    int syncTimeout() const;
    void setSyncTimeout(int timeout);

    bool useWaitBuffer() const;
    void setUseWaitBuffer(bool value);

    bool bufferedSyncTimeout() const;
    void setBufferedSyncTimeout(bool);

    bool syncWaiting() const;

    void classBegin() override;
    void componentComplete() override;

public Q_SLOTS:
    void updateUserValue();
    void activate();

Q_SIGNALS:
    void serverTargetChanged(QObject* serverTarget);
    void serverPropertyChanged(QString serverProperty);

    void userTargetChanged(QObject* userTarget);
    void userPropertyChanged(QString serverProperty);
    void userTriggerChanged(QString userTrigger);

    void syncTimeoutChanged(int timeout);
    void syncWaitingChanged(bool waiting);
    void bufferedSyncTimeoutChanged(bool);

    void useWaitBufferChanged(bool);

    // Emitted when we want to update the backend.
    void syncTriggered(const QVariant& value);

private Q_SLOTS:
    void serverSyncTimedOut();

private:
    void connectServer();
    void connectUser();

    QObject* m_serverTarget;
    QString m_serverProperty;

    QObject* m_userTarget;
    QString m_userProperty;
    QString m_userTrigger;

    bool m_classComplete;
    bool m_busy;

    QObject* m_connectedServerTarget;
    QObject* m_connectedUserTarget;

    QTimer* m_serverSync;
    bool m_useWaitBuffer;
    bool m_buffering;
    bool m_bufferedSyncTimeout;
};

#endif // SERVERPROPERTYSYNCHRONISER_H
