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

#ifndef APPLICATIONINSTANCE_H
#define APPLICATIONINSTANCE_H

// unity-api
#include <unity/shell/application/ApplicationInstanceInterface.h>

#include "MirSurfaceListModel.h"

#include <QList>
#include <QTimer>

class ApplicationInfo;

class ApplicationInstance : public unity::shell::application::ApplicationInstanceInterface
{
    Q_OBJECT

    // whether the test code will explicitly control the creation of the application surface
    Q_PROPERTY(bool manualSurfaceCreation READ manualSurfaceCreation WRITE setManualSurfaceCreation NOTIFY manualSurfaceCreationChanged)

public:
    ApplicationInstance(ApplicationInfo* application);

    // From ApplicationInstanceInterface
    State state() const override { return m_state; }
    RequestedState requestedState() const override;
    void setRequestedState(RequestedState) override;
    unity::shell::application::MirSurfaceListInterface* surfaceList() const override { return m_surfaceList; }
    unity::shell::application::MirSurfaceListInterface* promptSurfaceList() const override { return m_promptSurfaceList; }
    bool fullscreen() const override;
    unity::shell::application::ApplicationInfoInterface* application() const override;
    bool focused() const override;

    Q_INVOKABLE void setState(State value);

    bool manualSurfaceCreation() const { return m_manualSurfaceCreation; }
    void setManualSurfaceCreation(bool value);


    void setFocused(bool value);

    //////
    // internal mock stuff
    void close();
    void requestFocus();
    void setFullscreen(bool value);

Q_SIGNALS:
    void manualSurfaceCreationChanged(bool value);
    void closed();
    void focusRequested();

public Q_SLOTS:
    Q_INVOKABLE void createSurface();

private Q_SLOTS:
    void onSurfaceCountChanged();

private:
    State m_state{Starting};
    MirSurfaceListModel *m_surfaceList;
    MirSurfaceListModel *m_promptSurfaceList;
    QTimer m_surfaceCreationTimer;
    RequestedState m_requestedState{RequestedRunning};
    bool m_manualSurfaceCreation{false};
    int m_liveSurfaceCount{0};
    QList<MirSurface*> m_closingSurfaces;
    bool m_fullscreen{false};
    ApplicationInfo* m_application;
};

#endif // APPLICATIONINSTANCE_H
