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

#ifndef CACHING_IMAGE_PROVIDER_H_
#define CACHING_IMAGE_PROVIDER_H_

#include <QQuickImageProvider>
#include <QNetworkAccessManager>
#include <QThread>

#include <future>

class CachingTask: public QObject
{
    Q_OBJECT

public:
    CachingTask(QObject* parent = 0);

    void setUrl(QString const& url);
    QString url() const;

    std::future<QByteArray> getFuture();
    void setResult(QByteArray const& result);

private:
    std::promise<QByteArray> m_promise;
    QString m_url;
};

class CachingWorkerThread: public QThread
{
    Q_OBJECT

public:
    CachingWorkerThread(QObject* parent = 0);

    void run() override;

public Q_SLOTS:
    void processTask(CachingTask*);

private Q_SLOTS:
    void networkRequestFinished(QNetworkReply*);

private:
    QNetworkAccessManager* m_networkAccessManager;
    QMap<QNetworkReply*, CachingTask*> m_taskMap;
};

class CachingImageProvider : public QQuickImageProvider
{
public:
    CachingImageProvider();
    ~CachingImageProvider();
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize);

private:
    CachingWorkerThread m_workerThread;
};

#endif
