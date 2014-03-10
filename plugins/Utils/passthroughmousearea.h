/*
 * Copyright (C) 2014 Canonical, Ltd.
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

#ifndef PASSTHROUGHMOUSEAREA_H
#define PASSTHROUGHMOUSEAREA_H

#include <private/qquickmousearea_p.h>
#include <QPointer>

// Reports all mouse events received, like a regular MouseArea,
// but also let them pass through to reach items behind it
class PassthroughMouseArea : public QQuickMouseArea
{
    Q_OBJECT
public:
    PassthroughMouseArea(QQuickItem *parent = 0);
    ~PassthroughMouseArea();

protected:
    void mousePressEvent(QMouseEvent *event);
    void mouseUngrabEvent();

private Q_SLOTS:
    void onGrabbedReleased(QQuickMouseEvent* event);
    void clearConnected();

private:
    bool m_enabledEvents;
    QPointer<QQuickItem> m_passthroughGrabbed;
};

#endif // PASSTHROUGHMOUSEAREA_H
