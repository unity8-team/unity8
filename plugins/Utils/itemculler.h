/*
 * Copyright (C) 2016 Canonical, Ltd.
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

#ifndef ITEMCULLER_H
#define ITEMCULLER_H

#include <QObject>
#include <QPointer>

class QQuickItem;

// Culls an item, i.e. excludes it from the rendering process
// whithout changing the the visible property
class ItemCuller : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QQuickItem* target READ target WRITE setTarget NOTIFY targetChanged)

public:
    ItemCuller(QObject *parent = nullptr);
    ~ItemCuller();

    QQuickItem *target() const;
    void setTarget(QQuickItem *value);

Q_SIGNALS:
    void targetChanged(QQuickItem *value);

private:
    QPointer<QQuickItem> m_target;
};

#endif