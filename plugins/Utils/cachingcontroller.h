/*
 * Copyright 2014 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michal Hruby <michal.hruby@canonical.com>
*/

#ifndef CACHE_CONTROL_H_
#define CACHE_CONTROL_H_

#include <QNetworkAccessManager>
#include <QScopedPointer>
#include <QThread>

#include <future>

class CachingTask: public QObject
{
    Q_OBJECT

public:
    CachingTask(QObject* parent = 0);

    void setUrl(const QString& url);
    QString url() const;

    int hops() const;
    void hop();

    std::future<QByteArray> getFuture();
    void setResult(const QByteArray& result);

private:
    std::promise<QByteArray> m_promise;
    QString m_url;
    int m_hops;
};

class CachingThreadController: public QObject
{
    Q_OBJECT

public:
    CachingThreadController(QObject* parent = 0);

public Q_SLOTS:
    void processTask(CachingTask*);

private Q_SLOTS:
    void networkRequestFinished(QNetworkReply*);

private:
    QScopedPointer<QNetworkAccessManager> m_networkAccessManager;
    QMap<QNetworkReply*, CachingTask*> m_taskMap;
};

class CachingWorkerThread: public QThread
{
    Q_OBJECT

public:
    CachingWorkerThread(QObject* parent = 0);

    std::future<QByteArray> submitTask(const QString&);

private:
    QScopedPointer<CachingThreadController> m_controller;
};

#endif
