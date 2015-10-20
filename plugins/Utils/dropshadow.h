/*
 * Copyright (C) 2015 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef QUICKPLUSDROPSHADOW_H
#define QUICKPLUSDROPSHADOW_H

#include <QtQuick/QQuickItem>

class QuickPlusDropShadow : public QQuickItem
{
    Q_OBJECT
    Q_ENUMS(Quality)
    Q_PROPERTY(qreal size READ size WRITE setSize NOTIFY sizeChanged)
    Q_PROPERTY(qreal angle READ angle WRITE setAngle NOTIFY angleChanged)
    Q_PROPERTY(qreal distance READ distance WRITE setDistance NOTIFY distanceChanged)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(Quality quality READ quality WRITE setQuality NOTIFY qualityChanged)

public:
    QuickPlusDropShadow(QQuickItem* parent = 0);

    enum Quality { Low = 0, High = 1 };

    qreal size() const;
    void setSize(qreal size);
    qreal angle() const;
    void setAngle(qreal angle);
    qreal distance() const;
    void setDistance(qreal distance);
    QColor color() const;
    void setColor(const QColor& color);
    Quality quality() const;
    void setQuality(Quality quality);

Q_SIGNALS:
    void sizeChanged();
    void angleChanged();
    void distanceChanged();
    void colorChanged();
    void qualityChanged();

private:
    virtual QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data);

    enum { FilterDirty = (1 << 0) };

    QRgb m_color;
    quint16 m_size;
    quint16 m_angle;
    quint16 m_distance;
    quint8 m_quality : 1;
    quint8 __padding : 7;
    quint8 m_flags;

    Q_DISABLE_COPY(QuickPlusDropShadow)
};

QML_DECLARE_TYPE(QuickPlusDropShadow)

#endif  // QUICKPLUSDROPSHADOW_H
