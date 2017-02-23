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

#ifndef WINDOWED_MOUSE_POINTER_H
#define WINDOWED_MOUSE_POINTER_H

// From the real Cursor plugin
#include <MousePointer.h>

class WindowedMousePointer : public MousePointer {
    Q_OBJECT
public:
public Q_SLOTS:
    void handleMouseEvent(ulong timestamp, QPointF movement, QPointF position, Qt::MouseButtons buttons,
            Qt::KeyboardModifiers modifiers) override;
private:
    void matchMousePosition(ulong timestamp, QPointF position, Qt::MouseButtons buttons, Qt::KeyboardModifiers modifiers);

    bool m_wasMatchingPosition{false};
};

#endif // WINDOWED_MOUSE_POINTER_H
