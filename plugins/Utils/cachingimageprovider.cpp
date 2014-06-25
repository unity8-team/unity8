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

CacheControl::CacheControl(QObject* parent): QObject(parent)
{
}

void CacheControl::submitTask(CachingTask* task)
{
    // lazy init of the network access manager
    if (!m_networkAccessManager) {
        m_networkAccessManager.reset(new QNetworkAccessManager(this));
        QNetworkDiskCache* cache = new QNetworkDiskCache(this);
        cache->setCacheDirectory(QStandardPaths::writableLocation(QStandardPaths::CacheLocation));
        m_networkAccessManager->setCache(cache);

        QObject::connect(m_networkAccessManager.data(), &QNetworkAccessManager::finished, this, &CacheControl::networkRequestFinished, Qt::DirectConnection);
    }

    QNetworkReply *reply = m_networkAccessManager->get(QNetworkRequest(QUrl(task->url())));
    m_taskMap.insert(reply, task);
}

void CacheControl::networkRequestFinished(QNetworkReply* reply)
{
    reply->deleteLater();

    if (!m_taskMap.contains(reply)) {
        return;
    }

    CachingTask *task = m_taskMap.take(reply);

    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "Error downloading from the network:" << reply->errorString();
        task->setResult(QByteArray());
        task->deleteLater();
        return;
    }

    QVariant redirectUrl(reply->attribute(QNetworkRequest::RedirectionTargetAttribute));
    if (redirectUrl.isValid()) {
        // follow the url
        QUrl url(reply->url().resolved(redirectUrl.toUrl()));
        // update the task
        task->setUrl(url.toString());
        m_taskMap.insert(m_networkAccessManager->get(QNetworkRequest(url)), task);
        return;
    }

    task->setResult(reply->readAll());
    task->deleteLater();
}

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

CachingWorkerThread::CachingWorkerThread(QObject* parent): QThread(parent)
{
}

std::future<QByteArray> CachingWorkerThread::submitTask(QString const& uri)
{
    if (!m_controller) {
        m_controller.reset(new CacheControl);
        m_controller->moveToThread(this);
    }

    CachingTask *task = new CachingTask;
    task->setUrl(uri);
    task->moveToThread(this);
    task->setParent(this);

    QMetaObject::invokeMethod(m_controller.data(), "submitTask", Q_ARG(CachingTask*, task));

    return task->getFuture();
}

CachingImageProvider::CachingImageProvider()
    : QQuickImageProvider(QQmlImageProviderBase::Image, QQmlImageProviderBase::ForceAsynchronousImageLoading)
{
    qRegisterMetaType<CachingTask*>("CachingTask*");
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

    auto future = m_workerThread.submitTask(uri);

    QImage result;
    try {
        QByteArray data = future.get();
        result.loadFromData(data);
    } catch (...) {
        // just return the invalid image
    }

    *realSize = result.size();

    return result;
}
