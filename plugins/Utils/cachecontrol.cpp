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

#include "cachecontrol.h"

#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkDiskCache>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QStandardPaths>
#include <QByteArray>
#include <QUrl>
#include <QMutexLocker>

#define MAX_HOPS 20

CachingThreadController::CachingThreadController(QObject* parent): QObject(parent)
{
    qRegisterMetaType<CachingTask*>("CachingTask*");
}

QMutex* CachingThreadController::mutex()
{
    return &m_mutex;
}

void CachingThreadController::processTask(CachingTask* task)
{
    // lazy init of the network access manager
    if (!m_networkAccessManager) {
        m_networkAccessManager.reset(new QNetworkAccessManager(this));
        QNetworkDiskCache* cache = new QNetworkDiskCache(this);
        cache->setCacheDirectory(QStandardPaths::writableLocation(QStandardPaths::CacheLocation));
        m_networkAccessManager->setCache(cache);

        QObject::connect(m_networkAccessManager.data(), &QNetworkAccessManager::finished,
                         this, &CachingThreadController::networkRequestFinished);
    }

    QMutexLocker locker(&m_mutex);
    // the controller should own the task
    task->setParent(this);

    QNetworkReply *reply = m_networkAccessManager->get(QNetworkRequest(QUrl(task->url())));
    m_taskMap.insert(reply, task);
}

void CachingThreadController::networkRequestFinished(QNetworkReply* reply)
{
    reply->deleteLater();

    if (!m_taskMap.contains(reply)) {
        return;
    }

    QMutexLocker locker(&m_mutex);
    QScopedPointer<CachingTask> task(m_taskMap.take(reply));

    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "Error downloading from the network:" << reply->errorString();
        task->setResult(QByteArray());
        return;
    }

    QVariant redirectUrl(reply->attribute(QNetworkRequest::RedirectionTargetAttribute));
    if (redirectUrl.isValid() && task->hops() < MAX_HOPS) {
        // follow the url
        QUrl url(reply->url().resolved(redirectUrl.toUrl()));
        // update the task
        task->setUrl(url.toString());
        task->hop();
        m_taskMap.insert(m_networkAccessManager->get(QNetworkRequest(url)), task.take());
        return;
    }

    task->setResult(reply->readAll());
}

CachingTask::CachingTask(QObject* parent): QObject(parent), m_hops(0)
{
}

void CachingTask::setUrl(const QString& url)
{
    m_url = url;
}

QString CachingTask::url() const
{
    return m_url;
}

int CachingTask::hops() const
{
    return m_hops;
}

void CachingTask::hop()
{
    m_hops++;
}

std::future<QByteArray> CachingTask::getFuture()
{
    return m_promise.get_future();
}

void CachingTask::setResult(const QByteArray& result)
{
    m_promise.set_value(result);
}

CachingWorkerThread::CachingWorkerThread(QObject* parent): QThread(parent)
{
}

std::future<QByteArray> CachingWorkerThread::submitTask(const QString& uri)
{
    if (!m_controller) {
        m_controller.reset(new CachingThreadController);
        m_controller->moveToThread(this);
    }

    QMutexLocker locker(m_controller->mutex());
    CachingTask *task = new CachingTask;
    task->setUrl(uri);
    task->moveToThread(this);

    QMetaObject::invokeMethod(m_controller.data(), "processTask", Q_ARG(CachingTask*, task));

    return task->getFuture();
}
