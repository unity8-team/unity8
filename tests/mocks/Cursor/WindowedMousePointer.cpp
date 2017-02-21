/*
 * Copyright (C) 2017 Canonical, Ltd.
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License version 3, as published by
 * the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranties of MERCHANTABILITY,
 * SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "WindowedMousePointer.h"

// Qt
#include <qpa/qwindowsysteminterface.h>
#include <QQuickWindow>

void WindowedMousePointer::handleMouseEvent(ulong timestamp, QPointF movement, QPointF position, Qt::MouseButtons buttons,
        Qt::KeyboardModifiers modifiers)
{
    if (!parentItem()) {
        return;
    }

    if (!movement.isNull()) {
        Q_EMIT mouseMoved();
    }

    if (modifiers.testFlag(Qt::ShiftModifier)) {
        // put it back within shell bounds
        if (m_wasMatchingPosition) {
            setX(qBound(0.0, x(), parentItem()->width() - 1));
            setY(qBound(0.0, y(), parentItem()->height() - 1));
        }

        // Behave just like the real mouse in production which will do edge pushes, will be
        // constrained to scene boundaries and obeys item confinement. Useful for testing such features.
        applyMouseMovement(timestamp, movement, buttons, modifiers);

        m_wasMatchingPosition = false;
    } else {
        // Blindly follow host mouse pointer. Can go outside shell item boundaries, which is needed to reach the test UI controls
        // since they lie outside it.
        // It's also more intuitive as the tester expects the shell mouse to be where the host mouse is no matter what.
        matchMousePosition(timestamp, position, buttons, modifiers);
    }

}

void WindowedMousePointer::matchMousePosition(ulong timestamp, QPointF position, Qt::MouseButtons buttons, Qt::KeyboardModifiers modifiers)
{
    QPointF localPos = parentItem()->mapFromScene(position);
    setX(localPos.x());
    setY(localPos.y());
    m_wasMatchingPosition = true;
    QWindowSystemInterface::handleMouseEvent(window(), timestamp, position /*local*/, position /*global*/, buttons, modifiers);
}
