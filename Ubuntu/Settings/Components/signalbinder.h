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

#ifndef SIGNALBINDER_H
#define SIGNALBINDER_H

#include <QObject>
#include <QQmlParserStatus>

class SignalBinder : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)

    Q_PROPERTY(QObject* serverTarget READ serverTarget WRITE setServerTarget NOTIFY serverTargetChanged)
    Q_PROPERTY(QString serverProperty READ serverProperty WRITE setServerProperty NOTIFY serverPropertyChanged)

    Q_PROPERTY(QObject* clientTarget READ clientTarget WRITE setClientTarget NOTIFY clientTargetChanged)
    Q_PROPERTY(QString clientProperty READ clientProperty WRITE setClientProperty NOTIFY clientPropertyChanged)

    Q_PROPERTY(bool bidirectional READ bidirectional WRITE setBidirectional NOTIFY bidirectionalChanged)

public:
    SignalBinder(QObject* parent = nullptr);

    void classBegin() override;
    void componentComplete() override;

    QObject* serverTarget() const;
    void setServerTarget(QObject* target);

    QString serverProperty() const;
    void setServerProperty(const QString& property);

    QObject* clientTarget() const;
    void setClientTarget(QObject* target);

    QString clientProperty() const;
    void setClientProperty(const QString& property);

    bool bidirectional() const;
    void setBidirectional(bool bidirectional);

public Q_SLOTS:
    void updateServerValue();
    void updateClientValue();

Q_SIGNALS:
    void serverTargetChanged(QObject* serverTarget);
    void serverPropertyChanged(QString serverProperty);

    void clientTargetChanged(QObject* clientTarget);
    void clientPropertyChanged(QString serverProperty);

    void bidirectionalChanged(bool bidirectional);

private:
    void connectServer();
    void connectClient();

    QObject* m_serverTarget;
    QString m_serverProperty;

    QObject* m_clientTarget;
    QString m_clientProperty;

    bool m_bidirectional;
    bool m_classComplete;
    bool m_busy;

    QObject* m_connectedServerTarget;
    QObject* m_connectedClientTarget;
};

#endif // SIGNALBINDER_H
