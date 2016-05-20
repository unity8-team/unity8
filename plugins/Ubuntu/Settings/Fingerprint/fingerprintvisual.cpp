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

#include <QDebug>
#include "fingerprintvisual.h"

FingerprintVisual::FingerprintVisual(QObject* parent)
    : QSvgRenderer(parent)
    , m_source("")
{
}
FingerprintVisual::FingerprintVisual(const QList<QRectF> &masks, const QSize &size) :
    m_masks(masks)
    , m_size(size)
    , m_scale(4)
    , m_inactive(QLatin1String("../fingerprint_paths_gray.svg"))
    , m_active(QLatin1String("../fingerprint_paths_blue.svg"))
{
    QRectF bb = m_inactive.matrixForElement(
        SVG_ROOT_LAYER
    ).mapRect(m_inactive.boundsOnElement(SVG_ROOT_LAYER));

    // We will preserve aspect ratio, so we only consider the requested width.
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
    m_inactive.render(m_painter, SVG_ROOT_LAYER, bb);
}

FingerprintVisual::~FingerprintVisual()
{
    delete m_painter;
}

void FingerprintVisual::render()
{
    // No masks means we draw all active paths.
    if (m_masks.size() == 0) {
        m_active.render(m_painter);
        return;
    }

    foreach(const QString path, m_paths) {
        QMatrix mat = m_active.matrixForElement(path);
        QRectF bb = mat.mapRect(m_active.boundsOnElement(path));
        bb.moveLeft(bb.x() * m_scale);
        bb.moveTop(bb.y() * m_scale);
        bb.setWidth(bb.width() * m_scale);
        bb.setHeight(bb.height() * m_scale);

        foreach (const QRectF mask, m_masks) {
            if (mask.intersects(bb)) {
                renderPath(path);
            }
        }
    }
}

void FingerprintVisual::renderPath(const QString &id)
{
    if (!m_active.elementExists(id) || !m_inactive.elementExists(id))
        throw std::invalid_argument("Received non-existing id.");

    QMatrix mat = m_active.matrixForElement(id);
    QRectF bb = mat.mapRect(m_active.boundsOnElement(id));
    bb.moveLeft(bb.x() * m_scale);
    bb.moveTop(bb.y() * m_scale);
    bb.setWidth(bb.width() * m_scale);
    bb.setHeight(bb.height() * m_scale);
    m_active.render(m_painter, id, bb);
}

QPixmap FingerprintVisual::pixmap()
{
    return m_pixmap;
}
