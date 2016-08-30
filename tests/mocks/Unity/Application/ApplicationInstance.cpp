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

#include "ApplicationInstance.h"
#include "ApplicationInfo.h"
#include "MirSurface.h"
#include "SurfaceManager.h"

#define APPLICATION_DEBUG 1

#if APPLICATION_DEBUG
#define DEBUG_MSG(params) qDebug().nospace() << "ApplicationInstance["<<m_application->appId()<<","<<(void*)this<<"]::" << __func__  << " " << params

QString stateToStr(ApplicationInstance::State state)
{
    switch (state) {
    case ApplicationInstance::Starting:
        return "starting";
    case ApplicationInstance::Running:
        return "running";
    case ApplicationInstance::Suspended:
        return "suspended";
    case ApplicationInstance::Stopped:
        return "stopped";
    default:
        return "???";
    };
}

#else
#define DEBUG_MSG(params) ((void)0)
#endif

#define WARNING_MSG(params) qWarning().nospace() << "ApplicationInstance["<<m_application->appId()<<","<<(void*)this<<"]::" << __func__  << " " << params

using namespace unity::shell::application;

ApplicationInstance::ApplicationInstance(ApplicationInfo *application)
    : ApplicationInstanceInterface(application)
    , m_surfaceList(new MirSurfaceListModel(this))
    , m_promptSurfaceList(new MirSurfaceListModel(this))
    , m_application(application)
{
    DEBUG_MSG("");
    connect(m_surfaceList, &MirSurfaceListModel::countChanged,
        this, &ApplicationInstance::onSurfaceCountChanged, Qt::QueuedConnection);

    m_surfaceCreationTimer.setSingleShot(true);
    m_surfaceCreationTimer.setInterval(500);
    connect(&m_surfaceCreationTimer, &QTimer::timeout, this, &ApplicationInstance::createSurface);
    m_surfaceCreationTimer.start();
}

void ApplicationInstance::setState(State value)
{
    if (value != m_state) {
        DEBUG_MSG(qPrintable(stateToStr(value)));
        if (!m_manualSurfaceCreation && value == ApplicationInstance::Starting) {
            Q_ASSERT(m_surfaceList->count() == 0);
            m_surfaceCreationTimer.start();
        } else if (value == ApplicationInstance::Stopped) {
            m_surfaceCreationTimer.stop();
            for (int i = 0; i < m_surfaceList->count(); ++i) {
                MirSurface *surface = static_cast<MirSurface*>(m_surfaceList->get(i));
                surface->setLive(false);
            }
            for (int i = 0; i < m_promptSurfaceList->count(); ++i) {
                auto surface = static_cast<MirSurface*>(m_promptSurfaceList->get(i));
                surface->setLive(false);
            }
        }

        m_state = value;
        Q_EMIT stateChanged(value);
    }
}

void ApplicationInstance::createSurface()
{
    DEBUG_MSG("");
    if (state() == ApplicationInstance::Stopped) { return; }

    QString surfaceName = m_application->name();
    if (m_surfaceList->count() > 0) {
        surfaceName.append(QString(" %1").arg(m_surfaceList->count()+1));
    }

    auto surfaceManager = SurfaceManager::instance();
    if (!surfaceManager) {
        WARNING_MSG("No SurfaceManager");
        return;
    }

    auto surface = surfaceManager->createSurface(surfaceName,
           Mir::NormalType,
           fullscreen() ? Mir::FullscreenState : Mir::MaximizedState,
           m_application->screenshot());

    surface->setShellChrome(m_application->shellChrome());

    m_surfaceList->appendSurface(surface);

    ++m_liveSurfaceCount;
    connect(surface, &MirSurface::liveChanged, this, [this, surface](){
        if (!surface->live()) {
            --m_liveSurfaceCount;
            if (m_liveSurfaceCount == 0) {
                if (m_closingSurfaces.contains(surface)
                        || (m_state == Running && m_requestedState == RequestedRunning)) {
                    Q_EMIT closed();
                }
                setState(Stopped);
            } else {
                if (m_closingSurfaces.contains(surface) && m_requestedState == RequestedSuspended
                        && m_closingSurfaces.count() == 1) {
                    setState(Suspended);
                }
            }
            m_closingSurfaces.removeAll(surface);
        }
    });
    connect(surface, &MirSurface::closeRequested, this, [this, surface](){
        m_closingSurfaces.append(surface);
        if (m_state == Suspended) {
            // resume to allow application to close its surface
            setState(Running);
        }
    });
    connect(surface, &MirSurface::focusRequested, this, &ApplicationInstance::focusRequested);

    if (m_state == Starting) {
        if (m_requestedState == RequestedRunning) {
            setState(Running);
        } else {
            setState(Suspended);
        }
    }
}

ApplicationInstance::RequestedState ApplicationInstance::requestedState() const
{
    return m_requestedState;
}

void ApplicationInstance::setRequestedState(RequestedState value)
{
    if (m_requestedState == value) {
        return;
    }
    DEBUG_MSG((value == RequestedRunning ? "RequestedRunning" : "RequestedSuspended") );

    m_requestedState = value;
    Q_EMIT requestedStateChanged(m_requestedState);

    if (m_requestedState == RequestedRunning) {

        if (m_state == Suspended) {
            Q_ASSERT(m_liveSurfaceCount > 0);
            setState(Running);
        } else if (m_state == Stopped) {
            Q_ASSERT(m_liveSurfaceCount == 0);
            // it's restarting
            setState(Starting);
        }

    } else if (m_requestedState == RequestedSuspended && m_state == Running
            && m_closingSurfaces.isEmpty()) {
        setState(Suspended);
    }
}

void ApplicationInstance::onSurfaceCountChanged()
{
    if (m_surfaceList->count() == 0 && m_state == Running) {
        setState(Stopped);
    }
}

void ApplicationInstance::setManualSurfaceCreation(bool value)
{
    if (value != m_manualSurfaceCreation) {
        m_manualSurfaceCreation = value;
        Q_EMIT manualSurfaceCreationChanged(value);

        if (m_manualSurfaceCreation && m_surfaceCreationTimer.isActive()) {
            m_surfaceCreationTimer.stop();
        }
    }
}

void ApplicationInstance::close()
{
    DEBUG_MSG("");

    if (m_surfaceList->count() > 0) {
        for (int i = 0; i < m_surfaceList->count(); ++i) {
            MirSurface *surface = static_cast<MirSurface*>(m_surfaceList->get(i));
            surface->close();
        }
    } else {
        setState(Stopped);
        Q_EMIT closed();
    }
}

void ApplicationInstance::setFullscreen(bool value)
{
    m_fullscreen = value;
    if (m_surfaceList->rowCount() > 0) {
        m_surfaceList->get(0)->setState(Mir::FullscreenState);
    }
}

bool ApplicationInstance::fullscreen() const
{
    if (m_surfaceList->rowCount() > 0) {
        return m_surfaceList->get(0)->state() == Mir::FullscreenState;
    } else {
        return m_fullscreen;
    }
}

void ApplicationInstance::setFocused(bool value)
{
    if (focused() == value) {
        return;
    }

    if (value) {
        if (m_surfaceList->count() > 0) {
            m_surfaceList->get(0)->requestFocus();
        }
    } else {
        for (int i = 0; i < m_surfaceList->count(); ++i) {
            MirSurface *surface = static_cast<MirSurface*>(m_surfaceList->get(i));
            if (surface->focused()) {
                surface->setFocused(false);
            }
        }
    }
}

bool ApplicationInstance::focused() const
{
    bool someSurfaceHasFocus = false; // to be proven wrong
    for (int i = 0; i < m_surfaceList->count() && !someSurfaceHasFocus; ++i) {
        someSurfaceHasFocus = m_surfaceList->get(i)->focused();
    }
    return someSurfaceHasFocus;
}


void ApplicationInstance::requestFocus()
{
    if (m_surfaceList->count() == 0) {
        Q_EMIT focusRequested();
    } else {
        m_surfaceList->get(0)->requestFocus();
    }
}

ApplicationInfoInterface* ApplicationInstance::application() const
{
    return m_application;
}
