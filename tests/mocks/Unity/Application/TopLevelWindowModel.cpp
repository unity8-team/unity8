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

#include "TopLevelWindowModel.h"

#include "SurfaceManager.h"

Q_LOGGING_CATEGORY(TOPLEVELWINDOWMODEL, "toplevelwindowmodel", QtWarningMsg)

#define DEBUG_MSG qCDebug(TOPLEVELWINDOWMODEL).nospace().noquote() << __func__

namespace unityapi = unity::shell::application;

TopLevelWindowModel::TopLevelWindowModel()
{
    DEBUG_MSG;
    auto *appManNotifier = ApplicationManagerNotifier::instance();

    if (appManNotifier->applicationManager()) {
        setApplicationManager(appManNotifier->applicationManager());
    } else {
        connect(appManNotifier, &ApplicationManagerNotifier::applicationManagerChanged,
                this, &TopLevelWindowModel::setApplicationManager);
    }
}

TopLevelWindowModel::~TopLevelWindowModel()
{
    DEBUG_MSG;
}

unityapi::MirSurfaceInterface* TopLevelWindowModel::inputMethodSurface() const
{
    return m_inputMethodWindow ? m_inputMethodWindow->surface() : nullptr;
}

void TopLevelWindowModel::connectSurfaceManager()
{
    if (m_connectedSurfaceManager)
        return;

    auto surfaceManager = SurfaceManager::instance();
    Q_ASSERT(surfaceManager != nullptr);

    setInputMethodSurface(surfaceManager->inputMethodSurface());

    connect(surfaceManager, &SurfaceManager::inputMethodSurfaceChanged,
            this, [&]() {
        setInputMethodSurface(surfaceManager->inputMethodSurface());
    });

    connect(surfaceManager, &SurfaceManager::surfaceCreated,
        this, &TopLevelWindowModel::prependSurface);

    m_connectedSurfaceManager = true;
}

void TopLevelWindowModel::setApplicationManager(ApplicationManager* value)
{
    if (m_applicationManager == value) {
        return;
    }

    Q_ASSERT(m_modelState == IdleState);
    m_modelState = ResettingState;

    beginResetModel();

    if (m_applicationManager) {
        m_windowModel.clear();
        disconnect(m_applicationManager, 0, this, 0);
    }

    m_applicationManager = value;

    if (m_applicationManager) {
        // we're in business!
        connectSurfaceManager();

        connect(m_applicationManager, &QAbstractItemModel::rowsInserted,
                this, [this](const QModelIndex &/*parent*/, int first, int last) {
                    for (int i = first; i <= last; ++i) {
                        auto application = m_applicationManager->get(i);
                        addApplication(static_cast<ApplicationInfo*>(application));
                    }
                });

        connect(m_applicationManager, &QAbstractItemModel::rowsAboutToBeRemoved,
                this, [this](const QModelIndex &/*parent*/, int first, int last) {
                    for (int i = first; i <= last; ++i) {
                        auto application = m_applicationManager->get(i);
                        removeApplication(static_cast<ApplicationInfo*>(application));
                    }
                    // fake-miral
                    // Do it after ApplicationManager has finished changing its model
                    QMetaObject::invokeMethod(this, "focusTopMostAvailableWindow", Qt::QueuedConnection);
                });

        for (int i = 0; i < m_applicationManager->rowCount(); ++i) {
            auto application = m_applicationManager->get(i);
            addApplication(static_cast<ApplicationInfo*>(application));
        }
    }

    endResetModel();
    m_modelState = IdleState;
}

void TopLevelWindowModel::focusTopMostAvailableWindow()
{
    DEBUG_MSG << "()";
    setFocusedWindow(findFocusableWindow(0));
}

void TopLevelWindowModel::addApplication(ApplicationInfo *application)
{
    DEBUG_MSG << "(" << application->appId() << ")";

    if (application->state() != unityapi::ApplicationInfoInterface::Stopped && application->surfaceList()->count() == 0) {
        prependPlaceholder(application);
    } else {
        auto *surfaceList = application->surfaceList();
        for (int i = 0; i < surfaceList->count(); ++i) {
            prependSurface(static_cast<MirSurface*>(surfaceList->get(i)), application);
        }
    }
}

void TopLevelWindowModel::removeApplication(ApplicationInfo *application)
{
    DEBUG_MSG << "(" << application->appId() << ")";

    Q_ASSERT(m_modelState == IdleState);

    int i = 0;
    while (i < m_windowModel.count()) {
        if (m_windowModel.at(i).application == application) {
            removeAt(i);
        } else {
            ++i;
        }
    }

    DEBUG_MSG << " after " << toString();
}

void TopLevelWindowModel::prependPlaceholder(ApplicationInfo *application)
{
    DEBUG_MSG << "(" << application->appId() << ")";

    prependSurfaceHelper(nullptr, application);
}

void TopLevelWindowModel::prependSurface(MirSurface *surface, ApplicationInfo *application)
{
    Q_ASSERT(surface != nullptr);

    bool filledPlaceholder = false;
    for (int i = 0; i < m_windowModel.count() && !filledPlaceholder; ++i) {
        ModelEntry &entry = m_windowModel[i];
        if (entry.application == application && entry.window->surface() == nullptr) {
            // fake-miral: focus the newly added surface
            if (entry.window->focused()) {
                surface->setFocused(true);
            }

            entry.window->setSurface(surface);
            connectSurface(surface);
            DEBUG_MSG << " appId=" << application->appId() << " surface=" << surface
                      << ", filling out placeholder. after: " << toString();
            filledPlaceholder = true;
        }
    }

    if (!filledPlaceholder) {
        DEBUG_MSG << " appId=" << application->appId() << " surface=" << surface << ", adding new row";
        prependSurfaceHelper(surface, application);
    }
}

void TopLevelWindowModel::prependSurfaceHelper(MirSurface *surface, ApplicationInfo *application)
{
    if (m_modelState == IdleState) {
        m_modelState = InsertingState;
        beginInsertRows(QModelIndex(), 0 /*first*/, 0 /*last*/);
    } else {
        Q_ASSERT(m_modelState == ResettingState);
        // No point in signaling anything if we're resetting the whole model
    }

    int id = generateId();
    Window *window = new Window(id);
    if (surface) {
        window->setSurface(surface);
    }
    m_windowModel.prepend(ModelEntry(window, application));
    if (surface) {
        connectSurface(surface);
    }

    connect(window, &WindowInterface::focusRequested, this, [this, window]() {
        // fake-miral: just comply
        setFocusedWindow(window);
    });

    connect(window, &Window::closeRequested, this, [this, window]() {
        onWindowCloseRequested(window);
    });

    connect(window, &Window::stateRequested, this, [this, window](Mir::State requestedState) {
        onStateChangeRequested(window, requestedState);
    });

    if (m_modelState == InsertingState) {
        endInsertRows();
        Q_EMIT countChanged();
        Q_EMIT listChanged();
        m_modelState = IdleState;
    }

    // fake-miral: focus the newly added window
    setFocusedWindow(window);

    DEBUG_MSG << " after " << toString();
}

void TopLevelWindowModel::onWindowCloseRequested(Window *window)
{
    if (!window->surface()) {
        int index = indexOf(window);
        Q_ASSERT(index >= 0);
        m_windowModel[index].application->close();
    }
}

void TopLevelWindowModel::connectSurface(MirSurface *surface)
{
    connect(surface, &MirSurfaceInterface::liveChanged, this, [this, surface](bool live){
            if (!live) {
                onSurfaceDied(surface);
            }
        });

    connect(surface, &QObject::destroyed, this, [this, surface](){ this->onSurfaceDestroyed(surface); });
}

void TopLevelWindowModel::onStateChangeRequested(Window *window, Mir::State requestedState)
{
    if (requestedState == window->state()) {
        return;
    }

    // fake-miral

    window->setState(requestedState);

    if (requestedState == Mir::MinimizedState) {
        if (m_focusedWindow && m_focusedWindow == window) {
            setFocusedWindow(findFocusableWindow(indexOf(window)+1));
        }
    } else if (window->state() == Mir::MinimizedState || window->state() == Mir::HiddenState) {
        if (requestedState != Mir::MinimizedState && requestedState != Mir::HiddenState) {
            setFocusedWindow(window);
        }
    }
}

Window *TopLevelWindowModel::findFocusableWindow(int index)
{
    Q_ASSERT(index >= 0);

    // the simplest thing possible. this is a fake implementation afterall
    if (index < m_windowModel.count()) {
        auto candidate = m_windowModel[index].window;
        if (candidate->state() != Mir::MinimizedState && candidate->state() != Mir::HiddenState) {
            return candidate;
        } else {
            return findFocusableWindow(index + 1);
        }
    } else {
        return nullptr;
    }
}

void TopLevelWindowModel::onSurfaceDied(MirSurfaceInterface *surface)
{
    int i = indexOf(surface);
    if (i == -1) {
        return;
    }

    auto application = m_windowModel[i].application;

    // can't be starting if it already has a surface
    Q_ASSERT(application->state() != unityapi::ApplicationInfoInterface::Starting);

    if (application->state() == unityapi::ApplicationInfoInterface::Running) {
        m_windowModel[i].removeOnceSurfaceDestroyed = true;
    } else {
        // assume it got killed by the out-of-memory daemon.
        //
        // So leave entry in the model and only remove its surface, so shell can display a screenshot
        // in its place.
        m_windowModel[i].removeOnceSurfaceDestroyed = false;
    }
}

void TopLevelWindowModel::onSurfaceDestroyed(MirSurfaceInterface *surface)
{
    int i = indexOf(surface);
    if (i == -1) {
        return;
    }

    if (m_windowModel[i].removeOnceSurfaceDestroyed) {
        removeAt(i);
    } else {
        m_windowModel[i].window->setSurface(nullptr);
        DEBUG_MSG << " Removed surface from entry. After: " << toString();
    }

    disconnect(surface, 0, this, 0);
}

void TopLevelWindowModel::removeAt(int index)
{
    Q_ASSERT(index >= 0 && index < m_windowModel.count());

    if (m_modelState == IdleState) {
        beginRemoveRows(QModelIndex(), index, index);
        m_modelState = RemovingState;
    } else {
        Q_ASSERT(m_modelState == ResettingState);
        // No point in signaling anything if we're resetting the whole model
    }

    auto window = m_windowModel[index].window;
    if (window == focusedWindow()) {
        setFocusedWindow(nullptr);
    }

    m_windowModel.removeAt(index);

    delete window;

    if (m_modelState == RemovingState) {
        endRemoveRows();
        Q_EMIT countChanged();
        Q_EMIT listChanged();
        m_modelState = IdleState;
    }

    DEBUG_MSG << " after " << toString();
}

void TopLevelWindowModel::setInputMethodSurface(MirSurface *surface)
{
    if (m_inputMethodWindow) {
        qDebug("Multiple Input Method Surfaces created, removing the old one!");
        delete m_inputMethodWindow;
    }
    m_inputMethodWindow = new Window(generateId());
    m_inputMethodWindow->setSurface(surface);
    if (surface) {
        connectSurface(surface);
    }
    Q_EMIT inputMethodSurfaceChanged(m_inputMethodWindow->surface());
}

void TopLevelWindowModel::removeInputMethodWindow()
{
    if (m_inputMethodWindow) {
        delete m_inputMethodWindow;
        m_inputMethodWindow = nullptr;
        Q_EMIT inputMethodSurfaceChanged(nullptr);
    }
}

int TopLevelWindowModel::rowCount(const QModelIndex &/*parent*/) const
{
    return m_windowModel.count();
}

QVariant TopLevelWindowModel::data(const QModelIndex& index, int role) const
{
    if (index.row() < 0 || index.row() >= m_windowModel.size())
        return QVariant();

    if (role == WindowRole) {
        unityapi::WindowInterface *window = m_windowModel.at(index.row()).window;
        return QVariant::fromValue(window);
    } else if (role == ApplicationRole) {
        return QVariant::fromValue(m_windowModel.at(index.row()).application);
    } else {
        return QVariant();
    }
}

int TopLevelWindowModel::generateId()
{
    int id = m_nextId;
    m_nextId = nextFreeId(m_nextId + 1);
    Q_EMIT nextIdChanged();
    return id;
}

int TopLevelWindowModel::nextFreeId(int candidateId)
{
    if (candidateId > m_maxId) {
        return nextFreeId(1);
    } else {
        if (indexForId(candidateId) == -1) {
            // it's indeed free
            return candidateId;
        } else {
            return nextFreeId(candidateId + 1);
        }
    }
}

QString TopLevelWindowModel::toString()
{
    QString str;
    for (int i = 0; i < m_windowModel.count(); ++i) {
        auto item = m_windowModel.at(i);

        QString itemStr = QString("(index=%1,appId=%2,surface=0x%3,id=%4)")
            .arg(i)
            .arg(item.application->appId())
            .arg((qintptr)item.window->surface(), 0, 16)
            .arg(item.window->id());

        if (i > 0) {
            str.append(",");
        }
        str.append(itemStr);
    }
    return str;
}

int TopLevelWindowModel::indexOf(WindowInterface *window)
{
    for (int i = 0; i < m_windowModel.count(); ++i) {
        if (m_windowModel.at(i).window == window) {
            return i;
        }
    }
    return -1;
}

int TopLevelWindowModel::indexOf(MirSurfaceInterface *surface)
{
    for (int i = 0; i < m_windowModel.count(); ++i) {
        if (m_windowModel.at(i).window->surface() == surface) {
            return i;
        }
    }
    return -1;
}

int TopLevelWindowModel::indexForId(int id) const
{
    for (int i = 0; i < m_windowModel.count(); ++i) {
        if (m_windowModel[i].window->id() == id) {
            return i;
        }
    }
    return -1;
}

unityapi::WindowInterface *TopLevelWindowModel::windowAt(int index) const
{
    if (index >=0 && index < m_windowModel.count()) {
        return m_windowModel[index].window;
    } else {
        return nullptr;
    }
}

unityapi::MirSurfaceInterface *TopLevelWindowModel::surfaceAt(int index) const
{
    auto window = windowAt(index);
    return window ? window->surface() : nullptr;
}

unityapi::ApplicationInfoInterface *TopLevelWindowModel::applicationAt(int index) const
{
    if (index >=0 && index < m_windowModel.count()) {
        return m_windowModel[index].application;
    } else {
        return nullptr;
    }
}

int TopLevelWindowModel::idAt(int index) const
{
    if (index >=0 && index < m_windowModel.count()) {
        return m_windowModel[index].window->id();
    } else {
        return 0;
    }
}

void TopLevelWindowModel::raiseId(int id)
{
    if (m_modelState == IdleState) {
        DEBUG_MSG << "(id=" << id << ") - do it now.";
        doRaiseId(id);
    } else {
        DEBUG_MSG << "(id=" << id << ") - Model busy (modelState=" << m_modelState << "). Try again in the next event loop.";
        // The model has just signalled some change. If we have a Repeater responding to this update, it will get nuts
        // if we perform yet another model change straight away.
        //
        // A bad sympton of this problem is a Repeater.itemAt(index) call returning null event though Repeater.count says
        // the index is definitely within bounds.
        QMetaObject::invokeMethod(this, "raiseId", Qt::QueuedConnection, Q_ARG(int, id));
    }
}

void TopLevelWindowModel::doRaiseId(int id)
{
    int fromIndex = indexForId(id);
    if (fromIndex != -1) {
        move(fromIndex, 0);
    }
}

Window *TopLevelWindowModel::findWindowWithSurface(MirSurface *surface)
{
    for (int i = 0; i < m_windowModel.count(); ++i) {
        Window *window = m_windowModel[i].window;
        if (window->surface() == surface) {
            return window;
        }
    }
    return nullptr;
}

void TopLevelWindowModel::setFocusedWindow(Window *window)
{
    if (window != m_focusedWindow) {
        DEBUG_MSG << "(" << (window ? window->toString() : "null") << ")";

        Window* previousWindow = m_focusedWindow;

        // fake-miral: restore window if needed
        if (window && (window->state() == Mir::MinimizedState || window->state() == Mir::HiddenState)) {
            window->setState(Mir::RestoredState);
        }

        m_focusedWindow = window;
        Q_EMIT focusedWindowChanged(m_focusedWindow);

        if (previousWindow) {
            // fake-miral
            previousWindow->setFocused(false);
        }

        if (m_focusedWindow) {
            // fake-miral
            m_focusedWindow->setFocused(true);
            raiseId(m_focusedWindow->id());
        }
    }
}

unityapi::WindowInterface* TopLevelWindowModel::focusedWindow() const
{
    return m_focusedWindow;
}

void TopLevelWindowModel::move(int from, int to)
{
    if (from == to) return;
    DEBUG_MSG << " from=" << from << " to=" << to;

    if (from >= 0 && from < m_windowModel.size() && to >= 0 && to < m_windowModel.size()) {
        QModelIndex parent;
        /* When moving an item down, the destination index needs to be incremented
           by one, as explained in the documentation:
           http://qt-project.org/doc/qt-5.0/qtcore/qabstractitemmodel.html#beginMoveRows */

        Q_ASSERT(m_modelState == IdleState);
        m_modelState = MovingState;

        beginMoveRows(parent, from, from, parent, to + (to > from ? 1 : 0));
        m_windowModel.move(from, to);
        endMoveRows();

        m_modelState = IdleState;

        DEBUG_MSG << " after " << toString();

        Q_EMIT listChanged();
    }
}
