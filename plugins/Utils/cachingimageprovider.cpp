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

#include "cachingimageprovider.h"

#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkDiskCache>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QStandardPaths>
#include <QStringList>
#include <QByteArray>
#include <QImage>
#include <QUrl>
#include <QUrlQuery>

using namespace std;

CachingTask::CachingTask(QObject* parent): QObject(parent)
{
}

void CachingTask::setUrl(QString const& url)
{
    m_url = url;
}

QString CachingTask::url() const
{
    return m_url;
}

std::future<QByteArray> CachingTask::getFuture()
{
    return m_promise.get_future();
}

void CachingTask::setResult(QByteArray const& result)
{
    m_promise.set_value(result);
}

CachingWorkerThread::CachingWorkerThread(QObject* parent): QThread(parent),
    m_networkAccessManager(nullptr)
{
}

void CachingWorkerThread::run()
{
    QScopedPointer<QNetworkAccessManager> manager(new QNetworkAccessManager);
    QScopedPointer<QNetworkDiskCache> cache(new QNetworkDiskCache);
    cache->setCacheDirectory(QStandardPaths::writableLocation(QStandardPaths::CacheLocation));
    manager->setCache(cache.data());

    m_networkAccessManager = manager.data();
    QObject::connect(m_networkAccessManager, &QNetworkAccessManager::finished, this, &CachingWorkerThread::networkRequestFinished);

    // run the main loop
    exec();

    m_networkAccessManager = nullptr;
}

void CachingWorkerThread::processTask(CachingTask* task)
{
    QNetworkReply *reply = m_networkAccessManager->get(QNetworkRequest(QUrl(task->url())));
    m_taskMap.insert(reply, task);
}

void CachingWorkerThread::networkRequestFinished(QNetworkReply* reply)
{
    reply->deleteLater();

    if (!m_taskMap.contains(reply)) {
        return;
    }

    CachingTask *task = m_taskMap.take(reply);
    task->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "Error downloading from the network:" << reply->errorString();
        task->setResult(QByteArray());
        return;
    }

    task->setResult(reply->readAll());
}

CachingImageProvider::CachingImageProvider()
    : QQuickImageProvider(QQmlImageProviderBase::Image, QQmlImageProviderBase::ForceAsynchronousImageLoading)
{
    m_workerThread.start();
}

CachingImageProvider::~CachingImageProvider()
{
    m_workerThread.quit();
    m_workerThread.wait();
}

QImage CachingImageProvider::requestImage(const QString &id, QSize *realSize, const QSize &requestedSize) {
    Q_UNUSED(requestedSize)

    QUrlQuery query(id);
    if (!query.hasQueryItem(QLatin1String("u"))) {
        qWarning() << "Invalid uri for CachingImageProvider:" << id;
        return QImage();
    }

    QString uri = query.queryItemValue(QLatin1String("u"), QUrl::FullyEncoded);
    CachingTask *task = new CachingTask;
    task->moveToThread(&m_workerThread);
    task->setUrl(uri);

    QMetaObject::invokeMethod(&m_workerThread, "processTask", Qt::QueuedConnection, Q_ARG(CachingTask*, task));

    // FIXME: catch exceptions?
    QByteArray data = task->getFuture().get();

    QImage result;
    result.loadFromData(data);

    return result;
}
