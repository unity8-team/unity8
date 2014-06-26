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

    QString uri = query.queryItemValue(QLatin1String("u"), QUrl::FullyDecoded);

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
