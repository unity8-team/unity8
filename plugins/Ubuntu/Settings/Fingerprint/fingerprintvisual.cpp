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

#include <QDebug>
#include "fingerprintvisual.h"

FingerprintVisual::FingerprintVisual(const QList<QRectF> &masks, const QSize &size) :
    m_masks(masks)
    , m_size(size)
    , m_scale(4)
    , m_unenrolled_paths(QLatin1String(":assets/unenrolled.svg"))
    , m_enrolled_paths(QLatin1String(":assets/enrolled.svg"))
{
    if (!m_unenrolled_paths.isValid())
        qCritical() << "failed to open inactive paths";
    if (!m_enrolled_paths.isValid())
        qCritical() << "failed to open active paths";

    QRectF bb = m_unenrolled_paths.matrixForElement(
        SVG_ROOT_LAYER
    ).mapRect(m_unenrolled_paths.boundsOnElement(SVG_ROOT_LAYER));

    // We will preserve aspect ratio, so we only consider the requested width.
    // Scale is the scale at which we need to scale up/down the default SVG
    // size in order to meet the requested size.
    if (m_size.width() > 0) {
        m_scale = m_size.width() / bb.width();
    }

    // Move the base layer per scale.
    bb.moveLeft(bb.x() * m_scale);
    bb.moveTop(bb.y() * m_scale);
    bb.setWidth(bb.width() * m_scale);
    bb.setHeight(bb.height() * m_scale);

    // Draw the gray fingerprint onto the pixmap, doubling margins, if any.
    m_pixmap = QPixmap(bb.width() + (bb.x() * 2),
                       bb.height() + (bb.y() * 2));
    m_pixmap.fill(Qt::white); // for testing
    m_painter = new QPainter(&m_pixmap);
    m_unenrolled_paths.render(m_painter, SVG_ROOT_LAYER, bb);
}

FingerprintVisual::~FingerprintVisual()
{
    delete m_painter;
}

void FingerprintVisual::render()
{
    // No masks means we draw no active paths.
    if (m_masks.size() == 0) {
        return;
    }

    // For all paths, check if a mask intersects with it, in which case we
    // render that path as enrolled.
    for (int i = 0; i < m_paths.size(); i++) {
        QString path = m_paths.at(i);
        QMatrix mat = m_enrolled_paths.matrixForElement(path);
        QRectF bb = mat.mapRect(m_enrolled_paths.boundsOnElement(path));
        bb.moveLeft(bb.x() * m_scale);
        bb.moveTop(bb.y() * m_scale);
        bb.setWidth(bb.width() * m_scale);
        bb.setHeight(bb.height() * m_scale);

        for (int j = 0; j < m_masks.size(); j++) {
            QRectF mask = m_masks.at(j);
            if (mask.intersects(bb)) {

                // A substantive part should intersect.
                const QRectF sum = mask.intersected(bb);
                qreal wPct = (100 / bb.width()) * sum.width();
                qreal hPct = (100 / bb.height()) * sum.height();

                if (wPct > 25 && hPct > 25) {
                    renderPath(path);
                }
            }
        }
    }
}

void FingerprintVisual::renderPath(const QString &id)
{
    if (!m_enrolled_paths.elementExists(id) || !m_unenrolled_paths.elementExists(id))
        throw std::invalid_argument("Received non-existing id.");

    // We translate and scale each path according to a matrix.
    QMatrix mat = m_enrolled_paths.matrixForElement(id);
    QRectF bb = mat.mapRect(m_enrolled_paths.boundsOnElement(id));
    bb.moveLeft(bb.x() * m_scale);
    bb.moveTop(bb.y() * m_scale);
    bb.setWidth(bb.width() * m_scale);
    bb.setHeight(bb.height() * m_scale);
    m_enrolled_paths.render(m_painter, id, bb);
}

QPixmap FingerprintVisual::pixmap()
{
    return m_pixmap;
}
