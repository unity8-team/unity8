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
 *
 * A class that draws fingerprint visuals.
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
    // Masks are QRect that represent a successfully enrolled area.
    explicit FingerprintVisual(const QList<QRectF> &masks, const QSize &size);
    ~FingerprintVisual();

    // Will draw a set of “inactive” ridges, then iterate over masks to draw
    // “active” ridges (ridges intersecting with a mask).
    void render();
    QPixmap pixmap();

private:
    void renderPath(const QString &id);
    QList<QRectF> m_masks;
    QSize m_size;
    qreal m_scale;
    QPixmap m_pixmap;
    QPainter *m_painter;

    // This should most likely be populated using an XML parser.
    QList<QString> m_paths = QList<QString>({ "path4261", "path4256", "path4254", "path4252", "path4250", "path4248", "path4246", "path4244", "path4242", "path4240", "path4238", "path4236", "path4234", "path4232", "path4230", "path4228", "path4226", "path4224", "path4222", "path4220", "path4218", "path4216", "path4214", "path4212", "path4210", "path4208", "path4206", "path4204", "path4202", "path4200", "path4198", "path4196", "path4194", "path4192", "path4190", "path4188", "path4186", "path4184", "path4182", "path4180", "path4178", "path4176", "path4174", "path4172", "path4170", "path4168", "path4166", "path4164", "path4162", "path4160", "path4158", "path4297" });

    // These two renderers represents the unenrolled and enrolled
    // fingerprint paths.
    // It is expected they share the same base layer, and that an ID from
    // one renderer is identical to one in the other.
    QSvgRenderer m_unenrolled_paths;
    QSvgRenderer m_enrolled_paths;
};

#endif // FINGERPRINTVISUAL_H
