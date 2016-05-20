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

#ifndef FINGERPRINTVISUAL_H
#define FINGERPRINTVISUAL_H

#include <QDebug>
#include <QSvgRenderer>
#include <QPainter>
#include <QRect>
#include <QPixmap>


#define SVG_ROOT_LAYER QLatin1String("layer1")

class FingerprintVisual
{
public:
    explicit FingerprintVisual(const QList<QRectF> &masks, const QSize &size);
    ~FingerprintVisual();
    void render();
    void renderPath(const QString &id);
    QPixmap pixmap();

private:
    QList<QRectF> m_masks;
    QSize m_size;
    qreal m_scale;
    QPixmap m_pixmap;
    QPainter *m_painter;

    // This should most likely be populated using an XML parser, but this is fine for now.
    // TODO(jgdx): parse the svg.
    QList<QString> m_paths = QList<QString>({ "path4261", "path4439", "path4441", "path4443", "path4445", "path4447", "path4449", "path4451", "path4453", "path4455", "path4457", "path4459", "path4461", "path4463", "path4465", "path4467", "path4469", "path4471", "path4473", "path4475", "path4477", "path4479", "path4481", "path4483", "path4300", "path5080", "path5078", "path5076", "path5074", "path5072", "path5070", "path5068", "path5066", "path5064", "path5062", "path5060", "path5058", "path5056", "path5054", "path5052", "path5050", "path5048", "path5046", "path5044", "path5042", "path5040", "path5038", "path5036", "path5034", "path5032", "path5030", "path5028", "path5026", "path5024", "path5022", "path5020", "path4297" });

    // These two renderers represents the gray and blue fingerprint paths.
    // It is expected they share the same base layer, and that an ID from
    // one renderer is identical in the other.
    QSvgRenderer m_inactive;
    QSvgRenderer m_active;
};

#endif // FINGERPRINTVISUAL_H
