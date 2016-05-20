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
 */

FingerprintVisualProvider::FingerprintVisualProvider()
    : QQuickImageProvider(QQuickImageProvider::Pixmap)
{
}

QPixmap FingerprintVisualProvider::requestPixmap(
    const QString &id, QSize *size, const QSize &requestedSize)
{
    QList<QRectF> masks = QList<QRectF>();
    foreach(const QString srectf, id.split("[", QString::SkipEmptyParts)) {

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

    qDebug() << "Masks for id" << id << masks;

    FingerprintVisual fv(masks, requestedSize);
    fv.render();

    return fv.pixmap();
}
