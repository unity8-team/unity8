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

#pragma once

#include <QLoggingCategory>

#include "ApplicationManager.h"

// unity-api
#include <unity/shell/application/TopLevelWindowModelInterface.h>

// local
#include "Window.h"

Q_DECLARE_LOGGING_CATEGORY(TOPLEVELWINDOWMODEL)

/*
    This is a copy of TopLevelWindowModel from qtmir (the real deal) with some small changes.

    Yes, this code duplication sucks

    IDEA: Move as much as possible of the implementation to TopLevelWindowModelInterface.h
    in unity-api
*/
class TopLevelWindowModel : public unity::shell::application::TopLevelWindowModelInterface
{
    Q_OBJECT

    /**
      The id to be used on the next entry created
      Useful for tests
     */
    Q_PROPERTY(int nextId READ nextId NOTIFY nextIdChanged)

public:
    TopLevelWindowModel();
    virtual ~TopLevelWindowModel();

    // From unity::shell::aplication::TopLevelWindowModelInterface
    unity::shell::application::MirSurfaceInterface* inputMethodSurface() const override;
    unity::shell::application::WindowInterface* focusedWindow() const override;

    // From QAbstractItemModel
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;

    // Own API
    int nextId() const { return m_nextId; }

public Q_SLOTS:
    // From unity::shell::aplication::TopLevelWindowModelInterface
    unity::shell::application::MirSurfaceInterface *surfaceAt(int index) const override;
    unity::shell::application::WindowInterface *windowAt(int index) const override;
    unity::shell::application::ApplicationInfoInterface *applicationAt(int index) const override;
    int idAt(int index) const override;
    int indexForId(int id) const override;
    void raiseId(int id) override;

Q_SIGNALS:
    // Own API
    void nextIdChanged();

private Q_SLOTS:
    void focusTopMostAvailableWindow();

private:
    void connectSurfaceManager();
    void setApplicationManager(ApplicationManager*);
    void doRaiseId(int id);
    int generateId();
    int nextFreeId(int candidateId);
    QString toString();
    int indexOf(WindowInterface *window);
    int indexOf(MirSurfaceInterface *surface);

    void setInputMethodSurface(MirSurface *surface);
    void setFocusedWindow(Window *window);
    void removeInputMethodWindow();
    void removeAt(int index);

    void addApplication(ApplicationInfo *application);
    void removeApplication(ApplicationInfo *application);

    void prependPlaceholder(ApplicationInfo *application);
    void prependSurface(MirSurface *surface, ApplicationInfo *application);
    void prependSurfaceHelper(MirSurface *surface, ApplicationInfo *application);

    void connectSurface(MirSurface *surface);

    void onStateChangeRequested(Window *window, Mir::State requestedState);
    void onSurfaceDied(MirSurfaceInterface *surface);
    void onSurfaceDestroyed(MirSurfaceInterface *surface);
    void onWindowCloseRequested(Window *window);

    Window *findWindowWithSurface(MirSurface *surface);

    Window *findFocusableWindow(int index);

    void move(int from, int to);

    struct ModelEntry {
        ModelEntry() {}
        ModelEntry(Window *window,
                   ApplicationInfo *application)
            : window(window), application(application) {}
        Window *window{nullptr};
        ApplicationInfo *application{nullptr};
        bool removeOnceSurfaceDestroyed{false};
    };

    QVector<ModelEntry> m_windowModel;
    Window* m_inputMethodWindow{nullptr};
    Window* m_focusedWindow{nullptr};
    int m_nextId{1};
    // Just something big enough that we don't risk running out of unused id numbers.
    // Not sure if QML int type supports something close to std::numeric_limits<int>::max() and
    // there's no reason to try out its limits.
    static const int m_maxId{1000000};

    ApplicationManagerInterface* m_applicationManager{nullptr};

    enum ModelState {
        IdleState,
        InsertingState,
        RemovingState,
        MovingState,
        ResettingState
    };
    ModelState m_modelState{IdleState};

    bool m_connectedSurfaceManager{false};
};
