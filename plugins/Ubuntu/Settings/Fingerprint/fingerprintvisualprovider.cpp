/*
 * Copyright (C) 2016 Canonical, Ltd.
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
 *
 * Authored by Jonas G. Drange <jonas.drange@canonical.com>
 */

#include "fingerprintvisual.h"
#include "fingerprintvisualprovider.h"

FingerprintVisualProvider::FingerprintVisualProvider()
    : QQuickImageProvider(QQuickImageProvider::Pixmap)
{
    Q_INIT_RESOURCE(paths);
}

QPixmap FingerprintVisualProvider::requestPixmap(
    const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(size);
    QList<QRectF> masks = QList<QRectF>();

    // Read, from the id, what masks should be rendered.
    QList<QString> split = id.split("[", QString::SkipEmptyParts);
    for (int i = 0; i < split.size(); i++) {
        QString srectf = split.at(i);

        // Regexp for both int and qreal.
        QRegExp rx("(\\d+(?:\\.\\d+)?),(\\d+(?:\\.\\d+)?),(\\d+(?:\\.\\d+)?),(\\d+(?:\\.\\d+)?)");
        rx.indexIn(srectf);
        QStringList captured = rx.capturedTexts();
        if (captured.length() != 5)
            continue; // Not enough captured text.

        bool ok = true;
        qreal x = captured.at(1).toDouble(&ok);
        if (!ok) {
            qWarning() << "Failed to convert x" << captured.at(1);
            continue;
        }
        qreal y = captured.at(2).toDouble(&ok);
        if (!ok) {
            qWarning() << "Failed to convert y" << captured.at(2);
            continue;
        }
        qreal w = captured.at(3).toDouble(&ok);
        if (!ok) {
            qWarning() << "Failed to convert width" << captured.at(3);
            continue;
        }
        qreal h = captured.at(4).toDouble(&ok);
        if (!ok) {
            qWarning() << "Failed to convert height" << captured.at(4);
            continue;
        }
        masks.append(QRectF(x,y,w,h));
    }
    FingerprintVisual fv(masks, requestedSize);
    try
    {
        fv.render();
    }
    catch (std::invalid_argument e)
    {
        qCritical() << "Failed to render fingerprint visual."
                    << "Path file(s) not loaded. Was (" << e.what() << ")";
    }
    return fv.pixmap();
}
