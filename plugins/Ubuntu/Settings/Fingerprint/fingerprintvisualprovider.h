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
 * Given a list of rectangles, this image provider will draw a fingerprint
 * visual where ridges, that intersects with some mask, will be drawn
 * differently than ridges not intersecting some mask.
 */

#ifndef FINGERPRINTVISUALPROVIDER_H
#define FINGERPRINTVISUALPROVIDER_H

#include <QDebug>
#include <QRect>
#include <QQuickImageProvider>
#include <QPixmap>

class FingerprintVisualProvider : public QQuickImageProvider
{
public:
    FingerprintVisualProvider();

    // id is a comma separated list of rects in this format:
    //     [x1,y1,width1,heigh1],…,[xN,yN,widthN,heightN]
    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize);
};

#endif // FINGERPRINTVISUALPROVIDER_H
