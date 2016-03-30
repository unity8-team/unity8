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

#include "itemculler.h"

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-pedantic"
#include <private/qquickitem_p.h>
#pragma GCC diagnostic pop

ItemCuller::ItemCuller(QObject *parent)
    : QObject(parent)
{
}

ItemCuller::~ItemCuller()
{
    if (m_target) {
        QQuickItemPrivate::get(m_target)->setCulled(false);
    }
}

QQuickItem *ItemCuller::target() const
{
    return m_target;
}

void ItemCuller::setTarget(QQuickItem *value)
{
    if (m_target == value) {
        return;
    }

    if (m_target) {
        QQuickItemPrivate::get(m_target)->setCulled(false);
    }

    m_target = value;
    if (m_target) {
        QQuickItemPrivate::get(m_target)->setCulled(true);
    }

    Q_EMIT targetChanged(value);
}
