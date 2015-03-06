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

#ifndef SERVERACTIVATIONSYNC_H
#define SERVERACTIVATIONSYNC_H

#include <QObject>
#include <QQmlParserStatus>
#include <QVariant>

class QTimer;

class ServerActivationSync : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)

    Q_PROPERTY(QObject* serverTarget READ serverTarget WRITE setServerTarget NOTIFY serverTargetChanged)
    Q_PROPERTY(QString serverProperty READ serverProperty WRITE setServerProperty NOTIFY serverPropertyChanged)

    Q_PROPERTY(QObject* userTarget READ userTarget WRITE setUserTarget NOTIFY userTargetChanged)
    Q_PROPERTY(QString userProperty READ userProperty WRITE setUserProperty NOTIFY userPropertyChanged)

    Q_PROPERTY(int syncTimeout READ syncTimeout WRITE setSyncTimeout NOTIFY syncTimeoutChanged)
    Q_PROPERTY(bool syncWaiting READ syncWaiting NOTIFY syncWaitingChanged)

    Q_PROPERTY(bool useWaitBuffer READ useWaitBuffer WRITE setUseWaitBuffer NOTIFY useWaitBufferChanged)

public:
    ServerActivationSync(QObject* parent = nullptr);

    void classBegin() override;
    void componentComplete() override;

    QObject* serverTarget() const;
    void setServerTarget(QObject* target);

    QString serverProperty() const;
    void setServerProperty(const QString& property);

    QObject* userTarget() const;
    void setUserTarget(QObject* target);

    QString userProperty() const;
    void setUserProperty(const QString& property);

    int syncTimeout() const;
    void setSyncTimeout(int timeout);

    bool useWaitBuffer() const;
    void setUseWaitBuffer(bool value);

    bool syncWaiting() const;

    Q_INVOKABLE void activate();

public Q_SLOTS:
    void updateUserValue();

Q_SIGNALS:
    void serverTargetChanged(QObject* serverTarget);
    void serverPropertyChanged(QString serverProperty);

    void userTargetChanged(QObject* userTarget);
    void userPropertyChanged(QString serverProperty);

    void syncTimeoutChanged(int timeout);
    void syncWaitingChanged(bool waiting);

    void useWaitBufferChanged(bool);

    void activated(const QVariant& value);

private Q_SLOTS:
    void serverSyncTimedOut();

private:
    void connectServer();

    QObject* m_serverTarget;
    QString m_serverProperty;

    QObject* m_userTarget;
    QString m_userProperty;

    bool m_classComplete;
    bool m_busy;

    QObject* m_connectedServerTarget;

    QTimer* m_serverSync;
    bool m_useWaitBuffer;
    bool m_buffering;
};

#endif // SERVERACTIVATIONSYNC_H
