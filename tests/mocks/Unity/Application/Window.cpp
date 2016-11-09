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

#include "Window.h"
#include "MirSurface.h"

#include <QQmlEngine>

#define WINDOW_DEBUG 0

#if WINDOW_DEBUG
#include <QDebug>
#define DEBUG_MSG(params) qDebug().nospace() << qPrintable(toString()) << "::" << __func__  << " " << params
#else
#define DEBUG_MSG(params) ((void)0)
#endif

using namespace unity::shell::application;

Window::Window(int id)
    : WindowInterface(nullptr)
    , m_id(id)
{
    DEBUG_MSG("");
    QQmlEngine::setObjectOwnership(this, QQmlEngine::CppOwnership);
}

Window::~Window()
{
    DEBUG_MSG("");
}

QPoint Window::position() const
{
    return m_position;
}

QPoint Window::requestedPosition() const
{
    return m_requestedPosition;
}

void Window::setRequestedPosition(const QPoint &value)
{
    if (value != m_requestedPosition) {
        m_requestedPosition = value;
        Q_EMIT requestedPositionChanged(m_requestedPosition);
        if (m_surface) {
            m_surface->setRequestedPosition(value);
        } else {
            // fake-miral: always comply
            m_position = m_requestedPosition;
            Q_EMIT positionChanged(m_position);
        }
    }
}

Mir::State Window::state() const
{
    return m_state;
}

bool Window::focused() const
{
    return m_focused;
}

bool Window::confinesMousePointer() const
{
    if (m_surface) {
        return m_surface->confinesMousePointer();
    } else {
        return false;
    }
}

int Window::id() const
{
    return m_id;
}

MirSurfaceInterface* Window::surface() const
{
    return m_surface;
}

void Window::requestState(Mir::State state)
{
    Q_EMIT stateRequested(state);
}

void Window::setState(Mir::State state)
{
    if (m_surface) {
        m_surface->setState(state);
    } else {
        m_state = state;
        Q_EMIT stateChanged(m_state);
    }
}

void Window::requestFocus()
{
    if (m_surface) {
        m_surface->requestFocus();
    } else {
        Q_EMIT focusRequested();
    }
}

void Window::close()
{
    if (m_surface) {
        m_surface->close();
    } else {
        Q_EMIT closeRequested();
    }
}

void Window::setSurface(MirSurface *surface)
{
    if (m_surface) {
        disconnect(m_surface, 0, this, 0);
    }

    m_surface = surface;

    if (m_surface) {
        connect(surface, &MirSurfaceInterface::focusRequested, this, [this]() {
            Q_EMIT focusRequested();
        });

        connect(surface, &MirSurface::closeRequested, this, &Window::closeRequested);

        connect(surface, &MirSurface::stateRequested, this, [this](Mir::State state) {
            Q_EMIT stateRequested(state);
        });

        connect(surface, &MirSurfaceInterface::positionChanged, this, [this]() {
            updatePosition();
        });

        connect(surface, &MirSurfaceInterface::stateChanged, this, [this]() {
            updateState();
        });

        connect(surface, &MirSurfaceInterface::focusedChanged, this, [this]() {
            updateFocused();
        });

        // bring it up to speed
        m_surface->setRequestedPosition(m_requestedPosition);
        m_surface->requestState(m_state);

        // and sync with surface
        updatePosition();
        updateState();
        updateFocused();
    }

    Q_EMIT surfaceChanged(surface);
}

void Window::updatePosition()
{
    if (m_surface->position() != m_position) {
        m_position = m_surface->position();
        Q_EMIT positionChanged(m_position);
    }
}

void Window::updateState()
{
    if (m_surface->state() != m_state) {
        m_state = m_surface->state();
        Q_EMIT stateChanged(m_state);
    }
}

void Window::updateFocused()
{
    if (m_surface->focused() != m_focused) {
        m_focused = m_surface->focused();
        Q_EMIT focusedChanged(m_focused);
    }
}


void Window::setFocused(bool value)
{
    if (value != m_focused) {
        DEBUG_MSG("(" << value << ")");
        m_focused = value;
        Q_EMIT focusedChanged(m_focused);
        if (m_surface) {
            m_surface->setFocused(m_focused);
        }
    } else {
        DEBUG_MSG("(" << value << ") - NOOP");
    }
}

QString Window::toString() const
{
    if (surface()) {
    return QString("Window[0x%1, id=%2, MirSurface[0x%3,\"%4\"]]")
            .arg((quintptr)this, 0, 16)
            .arg(id())
            .arg((quintptr)surface(), 0, 16)
            .arg(surface()->name());
    } else {
        return QString("Window[0x%1, id=%2, null]")
            .arg((quintptr)this, 0, 16)
            .arg(id());
    }
}
